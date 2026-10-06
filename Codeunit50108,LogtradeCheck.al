codeunit 50108 "LogTradeLockHelper"
{
    Permissions = tabledata "LTC Consignment Header" = r;

    procedure CheckIfConsignmentExists(SalesOrderNo: Code[20]): Boolean
    var
        LTCConsignmentHeader: Record "LTC Consignment Header";
    begin
        LTCConsignmentHeader.SetRange("Source Document Type", LTCConsignmentHeader."Source Document Type"::"Sales Order");
        LTCConsignmentHeader.SetRange("Source Document No.", SalesOrderNo);
        exit(not LTCConsignmentHeader.IsEmpty());
    end;
}