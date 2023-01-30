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

        // Set request URI and method
        Request.SetRequestUri('https://pdm.one-it.nl/test/license');
        Request.Method := 'POST';

        // Send verification request
        exit(SendRequest(Response));
    end;

    /// <summary>
    /// Sends a request to the external PDM API to activate the license.
    /// </summary>
    /// <param name="Response">VAR HttpResponseMessage.</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure SendActivationRequest(var Response: HttpResponseMessage): Boolean
    var
        Headers: HttpHeaders;
    begin
        SetupGlobalVars();

        // Request headers
        Request.GetHeaders(Headers);
        Headers.Add('api-license-key', Format(PdmSetup.ApiLicenseKey));
        Headers.Add('api-company-id', Format(PdmSetup.CompanyId));

        // Set request URI and method
        Request.SetRequestUri('https://pdm.one-it.nl/license/addCompanyId');
        Request.Method := 'POST';

        // Send request
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
        exit(Client.Send(Request, Response));
    end;

    /// <summary>
    /// Parses the HTTP error code into an error message for the end-user
    /// </summary>
    /// <param name="ResponseCode">Integer.</param>
    /// <returns>Return value of type Text.</returns>
    procedure ParseActivationResponseCode(ResponseCode: Integer): Text
    begin
        case ResponseCode of 
            400: 
                exit('Bad Request: Missing license key or company ID header.');
            404:
                exit('Unkown license key provided.');
            423:
                exit('License is already active and cannot be modified');
        end;
    end;

    /// <summary>
    /// Parses the HTTP error code into an error message for the end-user
    /// </summary>
    /// <param name="ResponseCode">Integer.</param>
    /// <returns>Return value of type Text.</returns>
    procedure ParseVerificationResponseCode(ResponseCode: Integer): Text
    begin
        case ResponseCode of 
            400:
                exit('Bad Request, missing license key or company ID header.');
            402:
                exit('License is inactive, this most likely means the expiration date and grace period has been exceeded.');
            404:
                exit('Not Found, the provided license could not be found in the external database.');
            405:
                exit('HTTP Method Not Allowed.');
            409:
                exit('Conflict, the provided license key and company ID point to conflicting licenses.');
            424:
                exit('Not Found, the provided company ID does not match a license in the external database.');
            else
                exit('Unknown error occurred!');
        end;
    end;

    /// <summary>
    /// Retreives the API license expiration date from a response
    /// </summary>
    /// <param name="Response">VAR HttpResponseMessage.</param>
    /// <returns>Return value of type Date.</returns>
    procedure GetExpiryDateFromResponse(var Response: HttpResponseMessage): Date
    var
        ResponseHeaders: HttpHeaders;
        ExpiryDateHeader: List of [Text];
        ExpiryDate: Date;
    begin
        ResponseHeaders := Response.Headers();
        if not (ResponseHeaders.Contains('api-license-expiry-date')) then
            Error('Reponse did not contain an expiry date for the entered license.');

        ResponseHeaders.GetValues('api-license-expiry-date', ExpiryDateHeader); // Runtime error if unsuccessful
        Evaluate(ExpiryDate, ExpiryDateHeader.Get(1)); // Runtime error if unsuccessful
        exit(ExpiryDate);
    end;

    /// <summary>
    /// Parses the api-grace-period header on the response to the related value of the PDM Status enum.
    /// </summary>
    /// <param name="Response">VAR HttpResponseMessage.</param>
    /// <returns>Return value of type Enum "PDM Status OKE97".</returns>
    procedure GetGracePeriodStatus(var Response: HttpResponseMessage): Enum "PDM Status OKE97"
    var
        Headers: HttpHeaders;
        Values: List of [Text];
        RawValue: Text;
        PdmStatus: Enum "PDM Status OKE97";
    begin
        Headers := Response.Headers();
        Headers.GetValues('api-grace-period', Values);
        Values.Get(1, RawValue);

        if RawValue = '' then
            Error('Failed to retreive grace period status from server reply.');
        
        case RawValue of 
            'disabled':
                exit(PdmStatus::Disabled);
            'inactive':
                exit(PdmStatus::Verified);
            'reset': // Not yet implemented on PDM API
                exit(PdmStatus::"Verification required");
            'active':
                exit(PdmStatus::"Grace period active");
            'exceeded':
                exit(PdmStatus::"Grace period exceeded");
        end;
    end;
}
