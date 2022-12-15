codeunit 70647565 "PDM Foundation OKE97"
{
    var
        PdmSetup: Record "PDM Setup OKE97";

    [EventSubscriber(ObjectType::Codeunit, 44, 'OnAfterDocumentReady', '', true, true)]
    procedure RunMergeFlow(ObjectId: Integer; ObjectPayload: JsonObject; DocumentStream: InStream; var TargetStream: OutStream; var Success: Boolean)
    var
        DocumentType: JsonToken;
        ReportId: JsonToken;
        Response: HttpResponseMessage;
        ResponseContent: HttpContent;
        ResponseContentStream: InStream;
        ApiKeyRec: Record "API Key OKE97";
        ApiKey: Text;
    begin
        PdmSetup.FindSet();
        ObjectPayload.Get('documenttype', DocumentType);
        ObjectPayload.Get('objectid', ReportId);

        if not (DocumentType.AsValue().AsText() = 'application/pdf') then
            exit; // Document is not pdf, so we cannot send it to the Pdftk API

        if not GetApiKey(ApiKeyRec, ReportId, ApiKey) then
            exit; // No API key found

        SendRequest(DocumentStream, ApiKey, Response);
        if not Response.IsSuccessStatusCode() then
            exit; // Server indicated an error occured, file not modified

        ResponseContent := Response.Content();
        if not ResponseContent.ReadAs(ResponseContentStream) then
            exit; // Response is not a stream

        Success := true;
        CopyStream(TargetStream, ResponseContentStream);
    end;

    local procedure SendRequest(SourcePdf: InStream; ApiKey: Text; var Response: HttpResponseMessage)
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
        Request.SetRequestUri('https://pdm.one-it.nl/v1/merge/background');
        Request.Method := 'POST';

        Client.Send(Request, Response);
    end;

    local procedure GetApiKey(ApiKeyRec: Record "API Key OKE97"; ReportId: JsonToken; var ApiKey: Text): Boolean
    begin
        PdmSetup.FindSet();
        ApiKeyRec.SetRange(ApiKeyRec.ReportId, ReportId.AsValue().AsInteger());
        if not ApiKeyRec.FindSet() then
            if not PdmSetup.AlwaysRunMerge then
                exit
            else
                PdmSetup.TestField(DefaultApiKey);

        if ApiKeyRec.Apikey = '' then
            ApiKey := PdmSetup.DefaultApiKey
        else
            ApiKey := ApiKeyRec.Apikey;

        if ApiKey = '' then
            exit(false)
        else
            exit(true);
    end;
}
