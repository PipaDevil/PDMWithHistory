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

    [EventSubscriber(ObjectType::Page, Page::"PDM Setup Wizard OKE97", 'OnCompletePdmSetupWizard', '', true, true)]
    procedure OnCompletePdmSetupWizard()
    var
        AssitedSetup: Codeunit "Guided Experience";
    begin
        AssitedSetup.CompleteAssistedSetup(ObjectType::Page, Page::"PDM Setup Wizard OKE97");
    end;
}
