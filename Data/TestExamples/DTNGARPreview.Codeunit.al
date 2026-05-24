codeunit 70830 "DTNGAR Preview"
{
    Subtype = Test;
    TestPermissions = Disabled;
    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"DTNGAR Management");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"DTNGAR Management");

        LibraryERM.CreateBankAccount(BankAccount);
        Commit();

        GuaranteeLibrary.CreateGuaranteeSetup(DTNGARSetup);
        DTNGARSetup.FindLast();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"DTNGAR Management");
    end;

    var
        DTNGARGuarantee: Record "DTNGAR Guarantee";
        DTNGARSetup: Record "DTNGAR Setup";
        BankAccount: Record "Bank Account";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        GuaranteeLibrary: Codeunit "DTNGAR Guarantees Library";
        LibraryERM: Codeunit "Library - ERM";
        IsInitialized: Boolean;
        LibraryInventory: Codeunit "Library - Inventory";
        UnitOfMeasure: Record "Unit of Measure";

    [MessageHandler]
    Procedure MessageHandler(Msg: Text[1024])
    begin

    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RequestPageHandler]
    procedure RPHPostGuaranteeBankWithCustLedgEntry(var RequestPage: TestRequestPage "DTNGAR Post Guarantees");
    var
        DTNGARAccountGroup: Record "DTNGAR Account Group";
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
                end;
            Format(ActionType::Seize):
                begin
                    RequestPage.PostingDate.SetValue(Today);
                    RequestPage.SeizureType.SetValue(SeizeType::Customer);
                    RequestPage.Amount.SetValue(Random(100));
                    RequestPage.IsTransactionPurposal.SetValue(false);
                    RequestPage.IsPreviousPost.SetValue(true);
                    RequestPage.OK().INVOKE();
                end;
            Format(ActionType::Return):
                begin
                    RequestPage.PostingDate.SetValue(Today);
                    RequestPage.Amount.SetValue(Random(1000));
                    RequestPage.EntryTypePost.SetValue(EntryType::Bank);
                    RequestPage.Account.SetValue(BankAccount."No.");
                    RequestPage.IsTransactionPurposal.SetValue(false);
                    RequestPage.IsPreviousPost.SetValue(true);
                    RequestPage.OK().INVOKE();
                end;
            Format(ActionType::Reclassify):
                begin
                    RequestPage.PostingDate.SetValue(Today);
                    RequestPage.IsTransactionPurposal.SetValue(false);
                    RequestPage.IsPreviousPost.SetValue(true);
                    RequestPage.OK().INVOKE();
                    Commit();
                end;
        end;
    end;

    [RequestPageHandler]
    procedure RPHGuaranteeBankPost(var RequestPage: TestRequestPage "DTNGAR Post Guarantees");
    var
        DTNGARAccountGroup: Record "DTNGAR Account Group";
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
                    RequestPage.IsPreviousPost.SetValue(true);
                    RequestPage.OK().INVOKE();
                end;
            Format(ActionType::Seize):
                begin
                    RequestPage.PostingDate.SetValue(Today);
                    RequestPage.SeizureType.SetValue(SeizeType::Customer);
                    RequestPage.Amount.SetValue(Random(100));
                    RequestPage.IsTransactionPurposal.SetValue(false);
                    RequestPage.IsPreviousPost.SetValue(true);
                    RequestPage.OK().INVOKE();
                end;
            Format(ActionType::Return):
                begin
                    RequestPage.PostingDate.SetValue(Today);
                    RequestPage.Amount.SetValue(Random(1000));
                    RequestPage.EntryTypePost.SetValue(EntryType::Bank);
                    RequestPage.Account.SetValue(BankAccount."No.");
                    RequestPage.IsTransactionPurposal.SetValue(false);
                    RequestPage.IsPreviousPost.SetValue(true);
                    RequestPage.OK().INVOKE();
                end;
            Format(ActionType::Reclassify):

                begin
                    RequestPage.PostingDate.SetValue(Today);
                    RequestPage.IsTransactionPurposal.SetValue(false);
                    RequestPage.IsPreviousPost.SetValue(true);
                    RequestPage.OK().INVOKE();
                    Commit();
                end;
        end;
    end;

    [HandlerFunctions('RPHPostGuaranteeBankWithCustLedgEntry,MessageHandler')]
    [Test]
    procedure GuaranteeOpensPreviewWithCustLedgEntry()
    var
        Customer: Record Customer;
        PurchaseOrderHeader: Record "Purchase Header";
        DTNGARBondCard: TestPage "DTNGAR Bond Card";
        GLPostingPreview: TestPage "G/L Posting Preview";
        MovGuarEntriesPreview: TestPage "DTNGAR Guar. Entries Preview";
    begin
        // [Escenario] Inicializar escenario
        Initialize();

        // Initialize purchase header
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        GuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::Bond, DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Received);
        Commit();

        // [Condiciones] No hay

        // [Ejecucion]
        DTNGARBondCard.Trap();
        PAGE.Run(PAGE::"DTNGAR Bond Card", DTNGARGuarantee);
        GuaranteeLibrary.DepositGuarantee(DTNGARGuarantee);

        MovGuarEntriesPreview.Trap();//AML

        // [Comprobacion]
        GLPostingPreview.Trap();
        GuaranteeLibrary.ExecutionGuarantee(DTNGARGuarantee);
        GLPostingPreviewHandlerCustLedgEntry(GLPostingPreview);

        GLPostingPreview.Last();//aml
        GLPostingPreview.Show.Invoke();//aml
        MovGuarEntriesPreview.OK().Invoke();//AML


        GLPostingPreview.OK().Invoke();
    end;


    [HandlerFunctions('RPHGuaranteeBankPost,MessageHandler')]
    [Test]
    procedure GuaranteeOpensPreviewWithOutCustLedEntry()
    var
        Customer: Record Customer;
        PurchaseOrderHeader: Record "Purchase Header";
        DTNGARBondCard: TestPage "DTNGAR Bond Card";
        GLPostingPreview: TestPage "G/L Posting Preview";
        MovGuarEntriesPreview: TestPage "DTNGAR Guar. Entries Preview";
    begin
        // [Escenario] Inicializar escenario
        Initialize();

        // Initialize purchase header
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        GuaranteeLibrary.CreateGuaranteeBankGuarante(DTNGARGuarantee, Customer."No.", PurchaseOrderHeader, DTNGARGuarantee.Type::Bond, DTNGARGuarantee."Guaranteed Type"::Customer, DTNGARSetup, DTNGARGuarantee."Guarantee Type"::Received);
        Commit();

        // [Condiciones] No hay

        // [Ejecucion]
        DTNGARBondCard.Trap();
        PAGE.Run(PAGE::"DTNGAR Bond Card", DTNGARGuarantee);

        MovGuarEntriesPreview.Trap();//AML

        // [Comprobacion]
        GLPostingPreview.Trap();
        GuaranteeLibrary.DepositGuarantee(DTNGARGuarantee);
        GLPostingPreviewHandler(GLPostingPreview);

        GLPostingPreview.Last();//aml
        GLPostingPreview.Show.Invoke();//aml
        MovGuarEntriesPreview.OK().Invoke();//AML

        GLPostingPreview.OK().Invoke();

    end;



    local procedure GLPostingPreviewHandler(var GLPostingPreview: TestPage "G/L Posting Preview")
    var
        DTNGARGuaranteeEntry: Record "DTNGAR Guarantee Entry";
        GLEntry: Record "G/L Entry";
        BankLedgerEntries: record "Bank Account Ledger Entry";
    begin
        GLPostingPreview.First();
        VerifyGLPostingPreviewLine(GLPostingPreview, GLEntry.TableCaption, 2);
        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, BankLedgerEntries.TableCaption, 1);
        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, DTNGARGuaranteeEntry.TableCaption, 1);

    end;

    local procedure GLPostingPreviewHandlerCustLedgEntry(var GLPostingPreview: TestPage "G/L Posting Preview")
    var
        DTNGARGuaranteeEntry: Record "DTNGAR Guarantee Entry";
        GLEntry: Record "G/L Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgerEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        GLPostingPreview.First();
        VerifyGLPostingPreviewLine(GLPostingPreview, GLEntry.TableCaption, 2);
        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, CustLedgerEntry.TableCaption, 1);
        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, DetailedCustLedgerEntry.TableCaption, 1);
        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, DTNGARGuaranteeEntry.TableCaption, 1);
    end;

    local procedure VerifyGLPostingPreviewLine(GLPostingPreview: TestPage "G/L Posting Preview"; TableName: Text; ExpectedEntryCount: Integer)
    var
        RecordForTableNameNotFoundErr: Label 'A record for Table Name %1 was not found.', Comment = '"No se ha encontrado un registro para la tabla: %1."';
        TableNameUnexpectedErr: Label 'Table Name %1 Unexpected number of records.', Comment = '"Incorrecto numero de registros para la tabla: %1."';
    begin
        Assert.AreEqual(TableName, GLPostingPreview."Table Name".Value, StrSubstNo(RecordForTableNameNotFoundErr, TableName));
        Assert.AreEqual(ExpectedEntryCount, GLPostingPreview."No. of Records".AsInteger(), StrSubstNo(TableNameUnexpectedErr, TableName));
    end;

    // local procedure CustEntriesPreviewHandler(var CustomerEntriesPreview: TestPage "Cust. Ledg. Entries Preview"; EntryType: Integer)
    // var
    //     DocTypeUnexpErr: Label 'Unexpected DocumentType in GuaranteesEntriesPreview', comment = '"Tipo documento  en Vista incorrecto Previa Mov. Garantia."';
    // begin
    //     CustomerEntriesPreview.First();
    //     Assert.AreEqual(EntryType, CustomerEntriesPreview."Document Type".AsDecimal(), DocTypeUnexpErr);
    //     CustomerEntriesPreview.OK().Invoke();
    // end;

    // local procedure BankEntriesPreviewHandler(var BankAccEntriesPreview: TestPage "Bank Acc. Ledg. Entr. Preview"; EntryType: Integer)
    // var
    //     DocTypeUnexpErr: Label 'Unexpected DocumentType in BankEntriesPreview', comment = '"Tipo documento incorrecto en Vista Previa Mov. Banco."';
    // begin
    //     BankAccEntriesPreview.First();
    //     Assert.AreEqual(EntryType, BankAccEntriesPreview."Document Type".AsDecimal(), DocTypeUnexpErr);
    //     BankAccEntriesPreview.OK().Invoke();
    // end;




}
