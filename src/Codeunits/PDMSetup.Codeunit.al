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
        PdmFoundation.VerifyLicenseKey(true);
        Message('PDM Setup completed, license has been succesfull verified.\Enter a default API key to get started, or open the API key list to add keys for specific reports.');
    end;

    
    
    /// <summary>
    /// This procedure is a subscriber to the 'OnAfterModifyEvent' of the 'PDM Setup OKE97' table.
    /// This procedure updates the record for the default api key when it is changed.
    /// </summary>
    /// <param name="Rec">VAR Record "PDM Setup OKE97".</param>
    /// <param name="xRec">VAR Record "PDM Setup OKE97".</param>
    /// <param name="RunTrigger">Boolean.</param>
    [EventSubscriber(ObjectType::Table, Database::"PDM Setup OKE97", 'OnAfterModifyEvent', '', true, true)]
    local procedure OnAfterModifyDefaultApiKeyEvent(var Rec: Record "PDM Setup OKE97"; var xRec: Record "PDM Setup OKE97"; RunTrigger: Boolean)
    var
        PdmFoundation: Codeunit "PDM Foundation OKE97";
    begin
        if (Rec.UseDefaultApiKey) then begin
            if not (Rec.DefaultApiKey = xRec.DefaultApiKey) then
                exit;

            PdmFoundation.UpdateDefaultApiKeyRec(Rec.DefaultApiKey);
        end;
        
    end;
}
