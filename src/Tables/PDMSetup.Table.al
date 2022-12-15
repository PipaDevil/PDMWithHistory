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
        field(2; AlwaysRunMerge; Boolean)
        {
            Caption = 'Use default API key when no key is setup';
        }
        field(3; DefaultApiKey; Text[250])
        {
            Caption = 'Default API key to use if no other key is specified';
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
