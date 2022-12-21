table 70647566 "PDM API Key OKE97"
{
    Caption = 'PDM API Key';

    fields
    {
        field(1; ReportId; Integer)
        {
            Caption = 'ReportId';
            DataClassification = SystemMetadata;
        }
        field(2; ReportName; Text[250])
        {
            Caption = 'Report';
            DataClassification = SystemMetadata;
        }
        field(3; Apikey; Text[250])
        {
            Caption = 'API key';
            DataClassification = OrganizationIdentifiableInformation;
        }
        field(4; Description; Text[250])
        {
            Caption = 'Description';
            DataClassification = SystemMetadata;
        }
        field(5; Status; Enum "PDM API Key Status OKE97")
        {
            Caption = 'Status';
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
