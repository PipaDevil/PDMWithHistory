codeunit 70647565 "PDM Foundation OKE97"
{
    var
        PdmSetup: Record "PDM Setup OKE97";
        ApiKeyRec: Record "PDM API Key OKE97";

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
            exit;

        ObjectPayload.Get('documenttype', DocumentType);
        ObjectPayload.Get('objectid', ReportId);
        ObjectPayload.Get('objectname', ReportName);

        if not (DocumentType.AsValue().AsText() = 'application/pdf') then
            exit; // Document is not pdf, so we cannot send it to the API

        if not ReportInApiKeyTable(ReportId) then
            InsertReportWithoutApiKey(ReportId, ReportName);

        if not GetApiKey(ReportId, ReportName, ApiKey) then
            exit; // No API key found

        if not SendRequest(DocumentStream, ApiKey, Response) then
            exit; // Server unreachable

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
        PdmSetup.FindSet();

        if not PdmSetup.UsePDM then
            exit(false);

        if PdmSetup.UseDefaultApiKey then
            PdmSetup.TestField(DefaultApiKey);

        PdmSetup.Testfield(BackgroundMergeUrl);

        exit(true);
    end;

    local procedure SendRequest(SourcePdf: InStream; ApiKey: Text; var Response: HttpResponseMessage): Boolean
    var
        CR: Char;
        LF: Char;
        Newline: Text;
        Client: HttpClient;
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        Request: HttpRequestMessage;
        TempBlob: Record "Temp Blob OKE97" temporary;
        RequestBodyOutStream: OutStream;
        RequestBodyInStream: InStream;
    begin
        // Newline character definition
        CR := 13;                   // Carriage return
        LF := 10;                   // Line feed
        Newline += '' + CR + LF;

        // Request headers
        Content.GetHeaders(ContentHeaders);
        ContentHeaders.Clear();
        ContentHeaders.Add('Content-Type', 'multipart/form-data; boundary=boundary');
        ContentHeaders.Add('api-key', ApiKey);

        // Setup request body as stream
        TempBlob.Blob.CreateOutStream(RequestBodyOutStream);
        RequestBodyOutStream.WriteText('--boundary' + Newline);

        // Fill request body with the SourcePdf file and appropriate headers
        RequestBodyOutStream.WriteText('Content-Disposition: form-data; name="sourcePdf"' + Newline);
        RequestBodyOutStream.WriteText('Content-Type: application/pdf' + Newline);
        RequestBodyOutStream.WriteText(Newline);
        CopyStream(RequestBodyOutStream, SourcePdf);
        RequestBodyOutStream.WriteText(Newline);
        RequestBodyOutStream.WriteText('--boundary');

        // Setup request content
        TempBlob.Blob.CreateInStream(RequestBodyInStream);
        Content.WriteFrom(RequestBodyInStream);

        Request.content := Content;
        Request.SetRequestUri(PdmSetup.BackgroundMergeUrl);
        Request.Method := 'POST';

        if not Client.Send(Request, Response) then begin
            SetKeyStatus("PDM API Key Status OKE97"::"Server Unreachable");
            exit(false);
        end else
            exit(true);
    end;

    local procedure ReportInApiKeyTable(ReportId: JsonToken): Boolean
    var
        ApiKeyRec: Record "PDM API Key OKE97";
    begin
        ApiKeyRec.SetRange(ApiKeyRec.ReportId, ReportId.AsValue().AsInteger());
        exit(ApiKeyRec.FindSet());
    end;

    local procedure GetApiKey(ReportId: JsonToken; ReportName: JsonToken; var ApiKey: Text): Boolean
    begin
        ApiKeyRec.Reset();
        ApiKeyRec.SetRange(ApiKeyRec.ReportId, ReportId.AsValue().AsInteger());
        if ApiKeyRec.FindSet() and (ApiKeyRec.Apikey <> '') then begin
            ApiKey := ApiKeyRec.Apikey;
            CheckRecordReportName(ApiKeyRec, ReportName);
        end
        else if PdmSetup.UseDefaultApiKey then
            ApiKey := PdmSetup.DefaultApiKey;

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

    local procedure SetKeyStatus(Status: Enum "PDM API Key Status OKE97")
    begin
        if ApiKeyRec.Status <> Status then begin
            ApiKeyRec.Status := Status;
            ApiKeyRec.Modify();
        end
    end;

    local procedure InsertReportWithoutApiKey(ReportId: JsonToken; ReportName: JsonToken)
    var
        ApiKeyRec: Record "PDM API Key OKE97";
    begin
        ApiKeyRec.Init();
        ApiKeyRec.ReportId := ReportId.AsValue().AsInteger();
        ApiKeyRec.ReportName := ReportName.AsValue().AsText();
        ApiKeyRec.Insert();
    end;

    local procedure CheckRecordReportName(var ApiKeyRec: Record "PDM API Key OKE97"; ReportName: JsonToken)
    begin
        if ApiKeyRec.ReportName = '' then begin
            ApiKeyRec.ReportName := ReportName.AsValue().AsText();
            ApiKeyRec.Modify();
        end;
    end;
}
