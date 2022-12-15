table 70647566 "API Key OKE97"
{
    Caption = 'API Key OKE97';

    fields
    {
        field(1; ReportId; Integer)
        {
            Caption = 'ReportId';
            DataClassification = SystemMetadata;
        }
        field(2; Apikey; Text[256])
        {
            Caption = 'Apikey';
            DataClassification = OrganizationIdentifiableInformation;
        }
        field(3; Description; Text[256])
        {
            Caption = 'Description';
            DataClassification = SystemMetadata;
        }
    }
    keys
    {
        key(PK; ReportId)
        {
            Clustered = true;
        }
    }
}
