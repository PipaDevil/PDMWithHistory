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

        
        if not LicenseHasBeenChecked() then
            if not VerifyLicenseKey(false) then
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
    /// <param name="SendErrMsg">Wether or not an error message should be shown if verification fails.</param>
    /// <returns>Returns a `Boolean`, where `true` is a valid license and `false` is an invalid license.</returns>
    procedure VerifyLicenseKey(SendErrMsg: Boolean): Boolean
    var
        VerificationResponse: HttpResponseMessage;
        NewStatus: Enum "PDM Status OKE97";
    begin
        if not ApiCommunication.SendVerificationRequest(VerificationResponse) then
            exit(false); // Server unreachable

        if not VerificationResponse.IsSuccessStatusCode() then begin
            if SendErrMsg then
                Message('License verification failed: ' + ApiCommunication.ParseVerificationResponseCode(VerificationResponse.HttpStatusCode));

            SetPdmStatus(PdmStatus::"Verification failed");
            exit(false); // Verification failed
        end;

        SetLicenseExpiryDate(ApiCommunication.GetExpiryDateFromResponse(VerificationResponse));
        
        //TEST: set status to verified or a grace period related status depending on headers
        NewStatus := ApiCommunication.GetGracePeriodStatus(VerificationResponse);      
        SetPdmStatus(NewStatus);
        exit(true); // Verification succeeded
    end;

    /// <summary>
    /// This procedure changes the status of the extension to the provided status. This status is only used internally to signify the current installation/verification status and should not be directly displayed to the end-user
    /// </summary>
    /// <param name="NewStatus">Enum "PDM Status OKE97".</param>
    procedure SetPdmStatus(NewStatus: Enum "PDM Status OKE97")
    var
        LocalPdmSetup: Record "PDM Setup OKE97" temporary;
    begin
        PdmSetup.Reset();
        if (not PdmSetup.Get()) and (NewStatus <> PdmStatus::"Fresh install") then
            Error('Failed to retreive PDM Setup record during status change.');

        case NewStatus of
            PdmStatus::"Fresh install":
                begin
                    LocalPdmSetup.Init();
                    PdmSetup.TransferFields(LocalPdmSetup);
                end;
            PdmStatus::"Grace period active",
            PdmStatus::Verified,
            PdmStatus::"Verification failed":
                    PdmSetup.LicenseCheckDate := Today();
            PdmStatus::"Grace period exceeded",
            PdmStatus::Disabled:
                    PdmSetup.UsePDM := false;
        end;

        PdmSetup.Status := NewStatus;
        PdmSetup.Modify();
    end;

    /// <summary>
    /// Sets the value of the 'LicenseExpiryDate' field to the provided date.
    /// </summary>
    /// <param name="ExpiryDate">Date.</param>
    procedure SetLicenseExpiryDate(ExpiryDate: Date)
    begin
        PdmSetup.Reset();
        if not PdmSetup.Get() then
            Error('Failed to retreive PDM Setup record during expiry date registration.');
        
        PdmSetup.LicenseExpiryDate := ExpiryDate;
        PdmSetup.Modify(false);
    end;

    /// <summary>
    /// Checks if the current report being ran has already been inserted into the list of reports
    /// </summary>
    /// <param name="ReportId">Integer.</param>
    /// <returns>Return value of type Boolean.</returns>
    local procedure ReportInApiKeyTable(ReportId: Integer): Boolean
    begin
        ApiKeyRec.Reset();
        ApiKeyRec.SetRange(ApiKeyRec.ReportId, ReportId);
        exit(ApiKeyRec.FindSet());
    end;

    /// <summary>
    /// This procedure finds the API key to use for the current report. 
    /// If no specific key has been specified for the report being ran, it defaults to the default API key if setup
    /// </summary>
    /// <param name="ReportId">JsonToken.</param>
    /// <param name="ReportName">JsonToken.</param>
    /// <param name="ApiKey">VAR Text.</param>
    /// <returns>Return value of type Boolean.</returns>
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

    /// <summary>
    /// Checks if the merge request went through successfully, and updates the status of the relevant API key.
    /// </summary>
    /// <param name="Response">Integer.</param>
    /// <returns>Return value of type Enum "PDM API Key Status OKE97".</returns>
    local procedure SuccesfulResponse(Response: HttpResponseMessage): Boolean
    var
        ApiKeyStatus: Enum "PDM API Key Status OKE97";
    begin
        ApiKeyStatus := ParseKeyStatus(Response.HttpStatusCode);
        SetKeyStatus(ApiKeyStatus);

        exit(Response.IsSuccessStatusCode());
    end;

    /// <summary>
    /// Parses an HTTP status code into a value of the "PDM API Key Status OKE97" enum
    /// </summary>
    /// <param name="ResponseStatus">Integer.</param>
    /// <returns>Return value of type Enum "PDM API Key Status OKE97".</returns>
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

    /// <summary>
    /// Adds the report being ran to the list of reports, without an API key
    /// </summary>
    /// <param name="ReportId">JsonToken.</param>
    /// <param name="ReportName">JsonToken.</param>
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

    /// <summary>
    /// Checks to see if the name of the report in the api key list matches the actual name of the report, and updates the name if it doesn't
    /// </summary>
    /// <param name="ApiKeyRec">VAR Record "PDM API Key OKE97".</param>
    /// <param name="ReportName">JsonToken.</param>
    local procedure CheckRecordReportName(var ApiKeyRec: Record "PDM API Key OKE97"; ReportName: JsonToken)
    begin
        if ApiKeyRec.ReportName = '' then begin
            ApiKeyRec.ReportName := ReportName.AsValue().AsText();
            ApiKeyRec.Modify();
        end;
    end;

    /// <summary>
    /// Inserts a record for the default key into the api key list table
    /// </summary>
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

    /// <summary>
    /// Updates the default api key record to list a new key
    /// </summary>
    /// <remarks>If NewKey key is an empty string, the key from the setup record is used</remarks>
    /// <param name="NewKey">Text.</param>
    procedure UpdateDefaultApiKeyRec(NewKey: Text)
    var
        DefaultApiKeyRec: Record "PDM API Key OKE97";
    begin
        DefaultApiKeyRec.SetRange(ReportId, 0);
        if not DefaultApiKeyRec.FindSet() then begin
            InsertDefaultKeyInApiKeyTable();
            DefaultApiKeyRec.SetRange(ReportId, 0);
        end;

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
        
        if not VerifyLicenseKey(false) then
            Error('License is not currently valid, make sure it has been entered correctly.')
        else
            Message('License successfully verified.');
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

    /// <summary>
    /// This procedure is a subscriber to the 'OnAfterValidateEvent' on the 'UsePDM' field of the 'PDM Setup OKE97' table.
    /// This procedure updates the status field to be in line with the value of the 'UsePDM' field.
    /// </summary>
    /// <param name="Rec">VAR Record "PDM Setup OKE97".</param>
    /// <param name="xRec">VAR Record "PDM Setup OKE97".</param>
    /// <param name="CurrFieldNo">Integer.</param>
    [EventSubscriber(ObjectType::Table, Database::"PDM Setup OKE97", 'OnAfterValidateEvent', 'UsePDM', true, true)]
    local procedure OnAfterValidateUsePDMEvent(var Rec: Record "PDM Setup OKE97"; var xRec: Record "PDM Setup OKE97"; CurrFieldNo: Integer)
    begin
        if (Rec.UsePDM = xRec.UsePDM) then
            exit;
        
        case Rec.UsePDM of
            true:
                Rec.Status := PdmStatus::"Verification required";
            false:
                Rec.Status := PdmStatus::Disabled;
        end;
    end;
    
    /// <summary>
    /// This procedure is a subscriber to the 'OnAfterValidateEvent' on the 'ApiLicenseKey' field of the 'PDM Setup OKE97' table.
    /// This procedure updates the status field to reflect the verification status of the new license key.
    /// </summary>
    /// <param name="Rec">VAR Record "PDM Setup OKE97".</param>
    /// <param name="xRec">VAR record "PDM Setup OKE97".</param>
    /// <param name="CurrFieldNo">Integer.</param>
    [EventSubscriber(ObjectType::Table, Database::"PDM Setup OKE97", 'OnAfterValidateEvent', 'ApiLicenseKey', true, true)]
    local procedure OnAfterValidateApiLicenseKeyEvent(var Rec: Record "PDM Setup OKE97"; var xRec: record "PDM Setup OKE97"; CurrFieldNo: Integer)
    begin
        if (Rec.ApiLicenseKey = xRec.ApiLicenseKey) then
            exit;

        Rec.Status := PdmStatus::"Verification required";
    end;
}
