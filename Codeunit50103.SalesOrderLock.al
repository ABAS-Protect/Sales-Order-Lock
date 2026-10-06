/*
    Author: Niklas Dougherty <nd@abas.se>
    Date: 2026-09-28
    Description: Prevent sales staff from reopening released sales order with warehouse activity.
*/

permissionset 50104 SalesOrderLock
{
    Assignable = true;
    Caption = 'App Permissions';
    Permissions =
        codeunit SalesOrderLock = X;
}

codeunit 50103 "SalesOrderLock"
{
    Permissions = tabledata "Warehouse Activity Line" = r,
                  tabledata "Warehouse Shipment Line" = r,
                  tabledata "Sales Shipment Header" = r;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Sales Document", 'OnBeforeReopenSalesDoc', '', false, false)]
    local procedure OnBeforeReopenSalesDoc(var SalesHeader: Record "Sales Header")
    var
        NoPermissionErr: Label 'This sales order cannot be reopened because warehouse activity exists.';
        WhseDocsExistWarningMsg: Label 'Warning: This sales order has warehouse documents or shipping consignments attached to it.';
    begin
        if not GuiAllowed then
            exit;

        if SalesHeader."No." = '' then exit;

        if CheckIfWarehouseDocumentsExist(SalesHeader."No.") then begin
            if not CheckIfPremiumUser() then
                Error(NoPermissionErr)
            else
                Message(WhseDocsExistWarningMsg);
        end;
    end;

    local procedure CheckIfWarehouseDocumentsExist(SalesOrderNo: Code[20]): Boolean
    var
        WhseShipmentLine: Record "Warehouse Shipment Line";
        WhseActivityLine: Record "Warehouse Activity Line";
        SalesShipmentHeader: Record "Sales Shipment Header";
        LogTradeLockHelper: Codeunit "LogTradeLockHelper";
        LogTradeModuleInfo: ModuleInfo;
        LogTradeAppId: Guid;
    begin
        WhseShipmentLine.SetRange("Source Type", Database::"Sales Line");
        WhseShipmentLine.SetRange("Source Subtype", 1); // 1 = Order
        WhseShipmentLine.SetRange("Source No.", SalesOrderNo);
        if not WhseShipmentLine.IsEmpty() then
            exit(true);

        WhseActivityLine.SetRange("Source Type", Database::"Sales Line");
        WhseActivityLine.SetRange("Source Subtype", 1); // 1 = Sales Order
        WhseActivityLine.SetRange("Source No.", SalesOrderNo);
        WhseActivityLine.SetRange("Activity Type", WhseActivityLine."Activity Type"::Pick);
        if not WhseActivityLine.IsEmpty() then
            exit(true);

        LogTradeAppId := '424ef2c1-1fe0-4551-8608-3de6dbb073e0';
        if NavApp.GetModuleInfo(LogTradeAppId, LogTradeModuleInfo) then begin
            if LogTradeLockHelper.CheckIfConsignmentExists(SalesOrderNo) then
                exit(true);
        end;

        SalesShipmentHeader.SetRange("Order No.", SalesOrderNo);
        if not SalesShipmentHeader.IsEmpty() then
            exit(true);

        exit(false);
    end;

    local procedure CheckIfPremiumUser(): Boolean
    var
        AccessControl: Record "Access Control";
    begin
        AccessControl.SetRange("User Security ID", UserSecurityId());
        AccessControl.SetRange("Role ID", 'SUPER');
        AccessControl.SetFilter("Company Name", '%1|%2', '', CompanyName());
        if not AccessControl.IsEmpty() then
            exit(true);

        AccessControl.Reset();
        AccessControl.SetRange("User Security ID", UserSecurityId());
        AccessControl.SetRange("Role ID", 'D365 BUS PREMIUM');
        AccessControl.SetFilter("Company Name", '%1|%2', '', CompanyName());

        exit(not AccessControl.IsEmpty());
    end;
}