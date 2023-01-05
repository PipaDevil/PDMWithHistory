/// <summary>
/// This codeunit facilitates communication with the external PDM API.
/// </summary>
codeunit 70647567 "PDM API Communication OKE97"
{
    Permissions =
        tabledata "PDM Setup OKE97" = R,
        tabledata "PDM API Key OKE97" = R,
        tabledata "PDM Temp Blob OKE97" = RIMD;

    var
        CR: Char;
        LF: Char;
        Newline: Text;
        Client: HttpClient;
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        Request: HttpRequestMessage;
        RequestURI: Text;
        TempBlob: Record "PDM Temp Blob OKE97" temporary;
        RequestBodyOutStream: OutStream;
        RequestBodyInStream: InStream;
        PdmSetup: Record "PDM Setup OKE97";
        ApiVersions: Enum "PDM API Versions OKE97";
        PDMFoundation: Codeunit "PDM Foundation OKE97";

    local procedure SetupGlobalVars()
    begin
        if not PdmSetup.Get() then
            Error('Failed to retreive PDM Setup record for API communication.');

        // Newline character definition
        CR := 13;                   // Carriage return
        LF := 10;                   // Line feed
        Newline += '' + CR + LF;

        // Content headers
        Content.GetHeaders(ContentHeaders);
        ContentHeaders.Clear();
    end;

    /// <summary>
    /// Sends a verification request to the external PDM API.
    /// </summary>
    /// <param name="Response">VAR HttpResponseMessage.</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure SendVerificationRequest(var Response: HttpResponseMessage): Boolean
    var
        Headers: HttpHeaders;
    begin
        SetupGlobalVars();

        // Request headers
        Request.GetHeaders(Headers);
        Headers.Add('api-license-key', Format(PdmSetup.ApiLicenseKey));
        Headers.Add('api-company-id', Format(PdmSetup.CompanyId));

        // Set request URI, content, and method
        Request.SetRequestUri('https://pdm.one-it.nl/test/license');
        Request.Method := 'POST';

        // Send verification request
        exit(SendRequest(Response));
    end;

    /// <summary>
    /// Sends a merge request to the external PDM API
    /// </summary>
    /// <param name="SourcePdf">InStream.</param>
    /// <param name="ApiKey">Text.</param>
    /// <param name="Response">VAR HttpResponseMessage.</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure SendMergeRequest(SourcePdf: InStream; ApiKey: Text; var Response: HttpResponseMessage): Boolean
    begin
        SetupGlobalVars();

        // Request headers
        ContentHeaders.Add('Content-Type', 'multipart/form-data; boundary=boundary');
        ContentHeaders.Add('api-key', ApiKey);

        // Setup request body as stream
        TempBlob.Blob.CreateOutStream(RequestBodyOutStream);
        RequestBodyOutStream.WriteText('--boundary' + Newline);

        // Fill request body with the SourcePdf file
        RequestBodyOutStream.WriteText('Content-Disposition: form-data; name="sourcePdf"' + Newline);
        RequestBodyOutStream.WriteText('Content-Type: application/pdf' + Newline);
        RequestBodyOutStream.WriteText(Newline);
        CopyStream(RequestBodyOutStream, SourcePdf);
        RequestBodyOutStream.WriteText(Newline);
        RequestBodyOutStream.WriteText('--boundary');

        // Setup request content
        TempBlob.Blob.CreateInStream(RequestBodyInStream);
        Content.WriteFrom(RequestBodyInStream);

        GetMergeRequestURI();
        Request.SetRequestUri(RequestURI);

        Request.Content := Content;
        Request.Method := 'POST';

        exit(SendRequest(Response));
    end;

    local procedure GetMergeRequestURI()
    begin
        case PdmSetup.ApiVersion of
            "PDM API Versions OKE97"::v1:
                RequestURI := 'https://pdm.one-it.nl/v1/merge/background';
        end;
    end;

    local procedure SendRequest(var Response: HttpResponseMessage): Boolean
    begin
        if not Client.Send(Request, Response) then begin
            PDMFoundation.SetKeyStatus("PDM API Key Status OKE97"::"Server Unreachable");
            exit(false);
        end else
            exit(true);
    end;
}
