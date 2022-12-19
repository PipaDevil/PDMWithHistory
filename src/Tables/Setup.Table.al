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
        field(3; ApiVersion; Enum "API Versions OKE97")
        {
            Caption = 'API version';
        }
        field(4; UseDefaultApiKey; Boolean)
        {
            Caption = 'Use default API key when no key is setup';
        }
        field(5; DefaultApiKey; Text[250])
        {
            Caption = 'Default API key to use if no other key is specified';
        }
        field(6; AllowEditReportId; Boolean)
        {
            Caption = 'Manual report ID entry';
        }
    }
    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}
