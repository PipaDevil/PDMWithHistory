codeunit 70647565 "Pdftk API PDM"
{
    [EventSubscriber(ObjectType::Codeunit, 44, 'OnAfterDocumentReady', '', true, true)]
    procedure RunMergeFlow(ObjectId: Integer; ObjectPayload: JsonObject; DocumentStream: InStream; var TargetStream: OutStream; var Success: Boolean)
    var
        DocumentType: JsonToken;
        Response: HttpResponseMessage;
        ResponseContent: HttpContent;
        ResponseContentStream: InStream;
    begin
        ObjectPayload.Get('documenttype', DocumentType);

        if not (DocumentType.AsValue().AsText() = 'application/pdf') then begin
            Success := false;
            exit; // Document is not pdf, so we cannot send it to the Pdftk API
        end;

        // TODO: get api key based on report 

        SendRequest(DocumentStream, 'ONTW-TEST_VOORBEELD', Response);
        if not Response.IsSuccessStatusCode() then begin
            Success := false;
            TargetStream.Write(DocumentStream);
            exit; // Server indicated an error occured, file not modified
        end;

        ResponseContent := Response.Content();
        if not ResponseContent.ReadAs(ResponseContentStream) then begin
            Success := false;
            exit; // Response is not a stream
        end;

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
        TempBlob: Record "Temp Blob PDM" temporary;
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
}
