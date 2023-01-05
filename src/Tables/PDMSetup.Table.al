/// <summary>
/// Table PDM Setup OKE97 (ID 70647567).
/// </summary>
table 70647567 "PDM Setup OKE97"
{
    Caption = 'PDM Setup ';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; UsePDM; Boolean)
        {
            Caption = 'Enable PDM';
        }
        field(3; ApiVersion; Enum "PDM API Versions OKE97")
        {
            Caption = 'API version';
        }

        field(4; ApiLicenseKey; Text[250])
        {
            Caption = 'API license key';
        }
        field(5; UseDefaultApiKey; Boolean)
        {
            Caption = 'Enable default API key';
            DataClassification = OrganizationIdentifiableInformation;
        }
        field(6; DefaultApiKey; Text[250])
        {
            Caption = 'Default API key';
            DataClassification = OrganizationIdentifiableInformation;
        }
        field(7; AllowEditReportId; Boolean)
        {
            Caption = 'Manual report ID entry';
        }
        field(8; CompanyId; guid)
        {
            Caption = 'Company ID';
        }
        field(9; LicenseCheckDate; Date)
        {
            Caption = 'Last license verification';
        }
        field(10; Status; Enum "PDM Status OKE97")
        {
            Caption = 'License verification result';
        }
    }
    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    trigger OnModify()
    begin
        if UsePDM then begin
            TestField(ApiLicenseKey);
            TestField(ApiVersion);
        end;

        if UseDefaultApiKey then
            TestField(DefaultApiKey);
    end;
}
