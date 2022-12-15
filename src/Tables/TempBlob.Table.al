table 70647565 "Temp Blob OKE97"
{
    Caption = 'Temp Blob OKE97';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Primary Key"; Integer)
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(2; "Blob"; Blob)
        {
            Caption = 'Blob';
            DataClassification = SystemMetadata;
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
