/// <summary>
/// Codeunit PDM Setup OKE97 (ID 70647566).
/// </summary>
codeunit 70647566 "PDM Setup OKE97"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Guided Experience", 'OnRegisterAssistedSetup', '', true, true)]
    local procedure OnRegisterAssistedSetup()
    var
        AssistedSetup: Codeunit "Guided Experience";
        GuidedExperienceType: Enum "Guided Experience Type";
        AssistedSetupGroup: Enum "Assisted Setup Group";
        VideoCategory: Enum "Video Category";
    begin
        if not AssistedSetup.Exists(GuidedExperienceType::"Assisted Setup", ObjectType::Page, Page::"PDM Setup Wizard OKE97") then
            AssistedSetup.InsertAssistedSetup('Setup PDM for first use', 'Setup PDM for first use', 'Setup PDM for first use', 1, ObjectType::Page, Page::"PDM Setup Wizard OKE97", AssistedSetupGroup::FirstInvoice, '',VideoCategory::FirstInvoice, '');
    end;

    /// <summary>
    /// This event subscriber gets called when the Assisted Setup Wizard completes, and attempts to verify and activate the provided license with the external PDM API
    /// </summary>
    [EventSubscriber(ObjectType::Page, Page::"PDM Setup Wizard OKE97", 'OnCompletePdmSetupWizard', '', true, true)]
    procedure OnCompletePdmSetupWizard()
    var
        AssitedSetup: Codeunit "Guided Experience";
        PdmFoundation: Codeunit "PDM Foundation OKE97";
        ApiCommunication: Codeunit "PDM API Communication OKE97";
        ActivationResponse: HttpResponseMessage;
        PdmStatus: Enum "PDM Status OKE97";
    begin
        AssitedSetup.CompleteAssistedSetup(ObjectType::Page, Page::"PDM Setup Wizard OKE97");
        
        if not ApiCommunication.SendActivationRequest(ActivationResponse) then begin
            PdmFoundation.SetPdmStatus(PdmStatus::"Connection failed");
            Error('Failed to contact server for license activation.');
        end;
        
        if not ActivationResponse.IsSuccessStatusCode() then begin
            PdmFoundation.SetPdmStatus(PdmStatus::"Verification failed");
            Error('License activation failed to complete: ' + ApiCommunication.ParseActivationResponseCode(ActivationResponse.HttpStatusCode));
        end;

        PdmFoundation.SetPdmStatus(PdmStatus::"Setup done");
        if not PdmFoundation.VerifyLicenseKey() then
            Error('License verification failed, please ensure you have entered the license key correctly.');
        
        PdmFoundation.SetPdmStatus(PdmStatus::Verified);
        PdmFoundation.SetLicenseExpiryDate(GetExpiryDateFromResponseHeader(ActivationResponse));
        Message('PDM Setup completed, license has been succesfull verified.\Enter a default API key to get started, or open the API key list to add keys for specific reports.');
    end;

    local procedure GetExpiryDateFromResponseHeader(var ActivationResponse: HttpResponseMessage): Date
    var
        ResponseHeaders: HttpHeaders;
        ExpiryDateHeader: List of [Text];
        ExpiryDate: Date;
    begin
        ResponseHeaders := ActivationResponse.Headers();
        if not (ResponseHeaders.Contains('api-license-expiry-date')) then
            Error('Reponse did not contain an expiry date for the entered license.');

        ResponseHeaders.GetValues('api-license-expiry-date', ExpiryDateHeader); // Runtime error if unsuccessful
        Evaluate(ExpiryDate, ExpiryDateHeader.Get(1));
        exit(ExpiryDate);
    end;
}
