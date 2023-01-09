/// <summary>
/// Codeunit PDM Foundation OKE97 (ID 70647565)
/// Provides procedures which make up the foundation of the PDM extension.
/// </summary>
codeunit 70647565 "PDM Foundation OKE97"
{
    Permissions =
        tabledata "PDM Setup OKE97" = RIM,
        tabledata "PDM API Key OKE97" = RIM;

    var
        ApiCommunication: Codeunit "PDM API Communication OKE97";
        PdmSetup: Record "PDM Setup OKE97";
        PdmStatus: Enum "PDM Status OKE97";
        ApiKeyRec: Record "PDM API Key OKE97";
        UsingDefaultApiKey: Boolean;

    /// <summary>
    /// This procedure subscribes to ReportManagement's OnAfterDocumentReady event, and is the main procedure of the PDM extension.
    /// 
    /// Do not manually call this procedure.
    /// </summary>
    /// <param name="ObjectId">Integer</param>
    /// <param name="ObjectPayload">JsonObject</param>
    /// <param name="DocumentStream">InStream</param>
    /// <param name="TargetStream">VAR OutStream</param>
    /// <param name="Success">VAR Boolean</param>
    [EventSubscriber(ObjectType::Codeunit, 44, 'OnAfterDocumentReady', '', true, true)]
    procedure RunMergeFlow(ObjectId: Integer; ObjectPayload: JsonObject; DocumentStream: InStream; var TargetStream: OutStream; var Success: Boolean)
    var
        DocumentType: JsonToken;
        ReportId: JsonToken;
        ReportName: JsonToken;
        Response: HttpResponseMessage;
        ResponseContent: HttpContent;
        ResponseContentStream: InStream;
        ApiKey: Text;
    begin
        if not VerifyPDMSetup() then
            exit; // PDM not setup correctly, or disabled due to license issue

        if not VerifyLicenseKey() then
            exit; // License key not (or no longer) valid according to external API database

        ObjectPayload.Get('documenttype', DocumentType);
        ObjectPayload.Get('objectid', ReportId);
        ObjectPayload.Get('objectname', ReportName);

        if not (DocumentType.AsValue().AsText() = 'application/pdf') then
            exit; // Document is not pdf, so we cannot send it to the API

        if not ReportInApiKeyTable(ReportId.AsValue().AsInteger()) then
            InsertReportWithoutApiKey(ReportId, ReportName);

        if not GetApiKey(ReportId, ReportName, ApiKey) then
            exit; // No API key found

        if not ApiCommunication.SendMergeRequest(DocumentStream, ApiKey, Response) then
            SetKeyStatus("PDM API Key Status OKE97"::"Server Unreachable");

        if not SuccesfulResponse(Response) then
            exit; // Server indicated an error occured, file not modified

        ResponseContent := Response.Content();
        if not ResponseContent.ReadAs(ResponseContentStream) then
            exit; // Response is not a stream

        Success := true;
        CopyStream(TargetStream, ResponseContentStream);
    end;

    local procedure VerifyPDMSetup(): Boolean
    begin
        PdmSetup.Reset();
        if not PdmSetup.Get() then
            exit(false);

        if not PdmSetup.UsePDM then
            exit(false);

        if (PdmSetup.Status = PdmStatus::Disabled) or (PdmSetup.Status = PdmStatus::"Verification failed") then
            exit(false);

        PdmSetup.Testfield(ApiLicenseKey);

        if PdmSetup.UseDefaultApiKey then
            PdmSetup.TestField(DefaultApiKey);
        PdmSetup.Testfield(ApiVersion);

        exit(true);
    end;

    /// <summary>
    /// Attempts to verify the validity of the license key stored in the `PDM Setup` table.
    /// Starting point for the license verification process.
    /// </summary>
    /// <returns>Returns a `Boolean`, where `true` is a valid license and `false` is an invalid license.</returns>
    procedure VerifyLicenseKey(): Boolean
    var
        VerificationResponse: HttpResponseMessage;
    begin
        if LicenseHasBeenChecked() then
            exit(true); // License has already been checked today

        if not ApiCommunication.SendVerificationRequest(VerificationResponse) then
            exit(false); // Server unreachable

        if not VerificationSucceeded(VerificationResponse) then begin
            SetPdmStatus(PdmStatus::"Verification failed");
            exit(false); // Verification failed
        end;

        exit(true); // Verification succeeded
    end;

    local procedure VerificationSucceeded(Response: HttpResponseMessage): Boolean
    begin
        if not Response.IsSuccessStatusCode() then
            exit(false); // Verification failed

        SetPdmStatus(PdmStatus::Verified);
        exit(true); // Verification succeeded
    end;

    procedure SetPdmStatus(NewStatus: Enum "PDM Status OKE97")
    var
        LocalPdmSetup: Record "PDM Setup OKE97" temporary;
    begin
        PdmSetup.Reset();
        if not PdmSetup.Get() then
            Error('Failed to retreive PDM Setup record during status change.');

        PdmSetup.Status := NewStatus;
        case NewStatus of
            PdmStatus::"Fresh install":
                begin
                    LocalPdmSetup.Init();
                    PdmSetup.TransferFields(LocalPdmSetup);
                end;
            PdmStatus::Verified:
                begin
                    PdmSetup.LicenseCheckDate := Today();
                end;
            PdmStatus::"Verification failed":
                begin
                    PdmSetup.LicenseCheckDate := Today();
                end;
            PdmStatus::Disabled:
                begin
                    PdmSetup.UsePDM := false;
                end;
        end;
        PdmSetup.Modify();
    end;

    local procedure ReportInApiKeyTable(ReportId: Integer): Boolean
    begin
        ApiKeyRec.Reset();
        ApiKeyRec.SetRange(ApiKeyRec.ReportId, ReportId);
        exit(ApiKeyRec.FindSet());
    end;

    local procedure GetApiKey(ReportId: JsonToken; ReportName: JsonToken; var ApiKey: Text): Boolean
    begin
        ApiKeyRec.Reset();
        ApiKeyRec.SetRange(ApiKeyRec.ReportId, ReportId.AsValue().AsInteger());
        if ApiKeyRec.FindSet() and (ApiKeyRec.Apikey <> '') then begin
            ApiKey := ApiKeyRec.Apikey;
            CheckRecordReportName(ApiKeyRec, ReportName);
        end else begin
            if PdmSetup.UseDefaultApiKey then
                ApiKey := PdmSetup.DefaultApiKey;

            if not ReportInApiKeyTable(0) then
                InsertDefaultKeyInApiKeyTable()
            else
                UpdateDefaultApiKeyRec('');
        end;

        if ApiKey = '' then
            exit(false)
        else
            exit(true);
    end;

    local procedure SuccesfulResponse(Response: HttpResponseMessage): Boolean
    var
        ApiKeyStatus: Enum "PDM API Key Status OKE97";
    begin
        ApiKeyStatus := ParseKeyStatus(Response.HttpStatusCode);
        SetKeyStatus(ApiKeyStatus);

        exit(Response.IsSuccessStatusCode());
    end;

    local procedure ParseKeyStatus(ResponseStatus: Integer): Enum "PDM API Key Status OKE97"
    begin
        case ResponseStatus of
            200:
                exit("PDM API Key Status OKE97"::Succes);
            401:
                exit("PDM API Key Status OKE97"::"Error 401");
            403:
                exit("PDM API Key Status OKE97"::"Error 403");
            404:
                exit("PDM API Key Status OKE97"::"Error 404");
            500:
                exit("PDM API Key Status OKE97"::"Error 500");
        end;
    end;

    /// <summary>
    /// Modifies the API key's status to the provided status.
    /// </summary>
    /// <param name="Status">Enum "PDM API Key Status OKE97".</param>
    procedure SetKeyStatus(Status: Enum "PDM API Key Status OKE97")
    begin
        if ApiKeyRec.Status <> Status then begin
            ApiKeyRec.Status := Status;
            ApiKeyRec.Modify();
        end
    end;

    local procedure InsertReportWithoutApiKey(ReportId: JsonToken; ReportName: JsonToken)
    var
        NewApiKeyRec: Record "PDM API Key OKE97";
    begin
        NewApiKeyRec.Init();
        NewApiKeyRec.ReportId := ReportId.AsValue().AsInteger();
        NewApiKeyRec.ReportName := ReportName.AsValue().AsText();
        NewApiKeyRec.Status := "PDM API Key Status OKE97"::New;
        NewApiKeyRec.Insert();
    end;

    local procedure CheckRecordReportName(var ApiKeyRec: Record "PDM API Key OKE97"; ReportName: JsonToken)
    begin
        if ApiKeyRec.ReportName = '' then begin
            ApiKeyRec.ReportName := ReportName.AsValue().AsText();
            ApiKeyRec.Modify();
        end;
    end;

    local procedure InsertDefaultKeyInApiKeyTable()
    var
        DefaultName: Text;
        DefaultDesc: Text;
        NewApiKeyRec: Record "PDM API Key OKE97";
    begin
        DefaultName := 'Default - Configured in PDM setup';
        DefaultDesc := 'Used when the report being ran does not have a key defined in this table';

        NewApiKeyRec.Init();
        NewApiKeyRec.ReportId := 0;
        NewApiKeyRec.ReportName := DefaultName;
        NewApiKeyRec.Apikey := PdmSetup.DefaultApiKey;
        NewApiKeyRec.Description := DefaultDesc;
        NewApiKeyRec.Status := "PDM API Key Status OKE97"::New;
        NewApiKeyRec.Insert();
    end;

    local procedure UpdateDefaultApiKeyRec(NewKey: Text)
    var
        DefaultApiKeyRec: Record "PDM API Key OKE97";
    begin
        DefaultApiKeyRec.SetRange(ReportId, 0);
        if not DefaultApiKeyRec.FindSet() then
            Error('Failed to find default API key in API key table');

        if (NewKey = '') then
            NewKey := PdmSetup.DefaultApiKey;
        
        DefaultApiKeyRec.Apikey := NewKey;
        DefaultApiKeyRec.ReportName := 'Default - Configured in PDM setup';
        DefaultApiKeyRec.Description := 'Used when the report being ran does not have a key defined in this table';
        DefaultApiKeyRec.Modify(true);
    end;

    /// <summary>
    /// Manually retries the verification of the set license key, regardless of when the last verification attempt was.
    /// </summary>
    /// <param name="StatusNotification">Notification.</param>
    procedure ManualLicenseVerification(StatusNotification: Notification)
    var
        LocalPdmSetup: Record "PDM Setup OKE97";
    begin
        if not LocalPdmSetup.Get() then
            exit;
        
        if not VerifyLicenseKey() then
            Error('License is not currently valid, make sure it has been entered correctly.');
    end;

    /// <summary>
    /// Checks to see if the license key has been verified today.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure LicenseHasBeenChecked(): Boolean
    begin
        PdmSetup.Reset();
        if not PdmSetup.Get() then
            Error('Could not retrieve PDM Setup record from database');

        if (PdmSetup.LicenseCheckDate = Today()) and (PdmSetup.Status = PdmStatus::Verified) then
            exit(true); // License has already been checked today

        exit(false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"PDM Setup OKE97", 'OnAfterValidateEvent', 'UsePDM', true, true)]
    local procedure OnAfterValidateUsePDMEvent(var Rec: Record "PDM Setup OKE97"; var xRec: Record "PDM Setup OKE97"; CurrFieldNo: Integer)
    begin
        if (Rec.UsePDM = xRec.UsePDM) then
            exit;
        
        case Rec.UsePDM of
            true:
                Rec.Status := PdmStatus::"Setup done";
            false:
                Rec.Status := PdmStatus::Disabled;
        end;
    end;
    
    [EventSubscriber(ObjectType::Table, Database::"PDM Setup OKE97", 'OnAfterValidateEvent', 'ApiLicenseKey', true, true)]
    local procedure OnAfterValidateApiLicenseKeyEvent(var Rec: Record "PDM Setup OKE97"; var xRec: record "PDM Setup OKE97"; CurrFieldNo: Integer)
    begin
        if (Rec.ApiLicenseKey = xRec.ApiLicenseKey) then
            exit;

        Rec.Status := PdmStatus::"Setup done";
    end;
    
    [EventSubscriber(ObjectType::Table, Database::"PDM Setup OKE97", 'OnAfterModifyEvent', '', true, true)]
    local procedure OnAfterModifyDefaultApiKeyEvent(var Rec: Record "PDM Setup OKE97"; var xRec: Record "PDM Setup OKE97"; RunTrigger: Boolean)
    begin
        if (Rec.UseDefaultApiKey) then begin
            if not (Rec.DefaultApiKey = xRec.DefaultApiKey) then
                exit;

            UpdateDefaultApiKeyRec(Rec.DefaultApiKey);
        end;
        
    end;
}
