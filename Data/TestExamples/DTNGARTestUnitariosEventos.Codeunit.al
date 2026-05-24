codeunit 70803 "DTNGAR TestUnitariosEventos"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        BankAccount: Record "Bank Account";
        DTNGARAccountGroup: Record "DTNGAR Account Group";
        DTNGARGuarantee: Record "DTNGAR Guarantee";
        GuaranteeLibrary: Codeunit "DTNGAR Guarantees Library";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        UnitOfMeasure: Record "Unit of Measure";

    [Test]
    [HandlerFunctions('RPHPostGuaranteeBank,MessageHandler,NavigateHandler')]
    procedure TestNavigate()
    var
        Customer: Record Customer;
        DTNGARGuaranteeEntry: Record "DTNGAR Guarantee Entry";
        DTNGarSetup: Record "DTNGAR Setup";
        GLEntry: Record "G/L Entry";
        PurchaseOrderHeader: Record "Purchase Header";
        LastGLEntry: Integer;
        LastledgerGuarantees: Integer;
        GeneralLedgerEntries: TestPage "General Ledger Entries";
    begin
        //Create bond 
        LibraryERM.CreateBankAccount(BankAccount);
        Commit();
        GuaranteeLibrary.CreateGuaranteeSetupBond(DTNGARSetup);
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        GuaranteeLibrary.AccountigGroupGuarantee(DTNGARAccountGroup);
        Commit();
        GuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::Bond, DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Received);
        Commit();

        GuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);

        //Deposit
        GuaranteeLibrary.DepositGuarantee(DTNGARGuarantee);
        GuaranteeLibrary.CheckGLEntry(LastGLEntry, DTNGARGuarantee);
        GuaranteeLibrary.CheckGuaranteesLedger(LastledgerGuarantees, DTNGARGuarantee, DTNGARGuaranteeEntry."Entry Type"::Deposit);
        GuaranteeLibrary.CheckGuaranteesStatus(DTNGARGuarantee);
        GuaranteeLibrary.CheckGuaranteesDate(DTNGARGuarantee);

        GuaranteeLibrary.InitLastEntries(LastledgerGuarantees, LastGLEntry);
        //Navigate
        GLEntry.Get(LastGLEntry);
        GeneralLedgerEntries.OpenView();
        GeneralLedgerEntries.GoToRecord(GLEntry);
        GeneralLedgerEntries."&Navigate".Invoke();
        GeneralLedgerEntries.Close();

    end;

    [PageHandler]
    procedure NavigateHandler(var Navigate: TestPage Navigate)
    begin
        Navigate.DocNoFilter.AssertEquals(DTNGARGuarantee."No.");
        Navigate.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    procedure CarteraDocumentsHandler(var CarteraDocuments: TestPage "Cartera Documents")
    var
    begin
        if CarteraDocuments.First() then
            CarteraDocuments.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ModalPageHandler179(var ReverseEntry: TestPage "Reverse Transaction Entries");
    begin
        ReverseEntry.Reverse.Invoke();
    end;

    [RequestPageHandler]
    procedure RejectDocsRequestPageHandler(var RejectDocs: TestRequestPage 7000097)
    begin
        RejectDocs.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure CarteraJournalModalPageHandler(var CarteraJournal: TestPage "Cartera Journal")
    begin
        CarteraJournal.Post.Invoke();
    end;

    [MessageHandler]
    Procedure MessageHandler(Msg: Text[1024])
    begin
    end;

    [RequestPageHandler]
    procedure RedrawReceivableBillsRequestPageHandler(var RedrawReceivableBillsRequestPageHandler: TestRequestPage 7000096)
    begin
        RedrawReceivableBillsRequestPageHandler.NewDueDate.SetValue(20301001D);//review
        RedrawReceivableBillsRequestPageHandler.AuxJnlTemplateName.Lookup();
        RedrawReceivableBillsRequestPageHandler.AuxJnlBatchName.Lookup();
        RedrawReceivableBillsRequestPageHandler.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure GeneralJournalTemplateListModalPageHandler(var GeneralJournalTemplateList: TestPage "General Journal Template List")
    begin
        if GeneralJournalTemplateList.First() then
            GeneralJournalTemplateList.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure GeneralJournalBatchesModalPage(var GeneralJournalBatches: TestPage "General Journal Batches")
    begin
        if GeneralJournalBatches.First() then
            GeneralJournalBatches.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure RPHPostGuaranteeBank(var RequestPage: TestRequestPage "DTNGAR Post Guarantees");
    var
        ActionType: Enum "DTNGAR PostTypeProcess";
        SeizeType: Enum "DTNGAR SeizureTypePostProcess";
        EntryType: Enum "DTNGAR EntryTypePostProcess";


    begin
        DTNGARAccountGroup.get(DTNGARGuarantee."Account Group");
        case RequestPage.Action.Value of
            Format(ActionType::Deposit):
                begin
                    RequestPage.PostingDate.SetValue(Today);
                    RequestPage.Amount.SetValue(LibraryRandom.RandDecInDecimalRange(10000, 40000, 2));
                    RequestPage.EntryTypePost.SetValue(EntryType::Bank);
                    RequestPage.Account.SetValue(BankAccount."No.");
                    RequestPage.IsTransactionPurposal.SetValue(false);
                    RequestPage.IsPreviousPost.SetValue(false);
                    RequestPage.OK().INVOKE();
                    Commit();
                end;
            Format(ActionType::Seize):
                begin
                    RequestPage.PostingDate.SetValue(Today);
                    RequestPage.SeizureType.SetValue(SeizeType::Customer);
                    RequestPage.Amount.SetValue(Random(100));
                    RequestPage.IsTransactionPurposal.SetValue(false);
                    RequestPage.IsPreviousPost.SetValue(false);
                    RequestPage.OK().INVOKE();
                    Commit();
                end;
            Format(ActionType::Return):
                begin
                    RequestPage.PostingDate.SetValue(Today);
                    RequestPage.Amount.SetValue(Random(1000));
                    RequestPage.EntryTypePost.SetValue(EntryType::Bank);
                    RequestPage.Account.SetValue(BankAccount."No.");
                    RequestPage.IsTransactionPurposal.SetValue(false);
                    RequestPage.IsPreviousPost.SetValue(false);
                    RequestPage.OK().INVOKE();
                    Commit();
                end;
            Format(ActionType::Reclassify):
                begin
                    RequestPage.PostingDate.SetValue(Today);
                    RequestPage.IsTransactionPurposal.SetValue(false);
                    RequestPage.IsPreviousPost.SetValue(false);
                    RequestPage.OK().INVOKE();
                    Commit();
                end;
        end;
    end;
}
