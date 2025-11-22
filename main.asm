INCLUDE Irvine32.inc

.data
    ; --- UI Strings & Messages ---
    EndingClause       BYTE "Bank Management System",0
    MsgWelcome         BYTE "*****************************************	Welcome To Banking System	****************************************",0
    MsgMainMenu        BYTE "Press 1 for New User",10,"Press 2 for Existing customer",10,"Press 3 to exit",0
    MsgTransaction     BYTE "Press 1 for Deposit",10,"Press 2 for Withdrawal",10,"Press 3 for showing money",10,"Press 4 to show details and Quit",0
    
    ; --- Prompts ---
    PromptUsername     BYTE "Enter user: ",0
    PromptPassword     BYTE "Enter Password: ",0
    PromptStartAmt     BYTE "Enter Starting Amount: ",0
    PromptWithdraw     BYTE "Enter Withdrawal Amount: ",0
    PromptDeposit      BYTE "Enter Deposit Amount: ",0
    PromptTransact     BYTE "Choose any transaction: ",0

    ; --- Status & Error Messages ---
    ErrInvalidInput    BYTE "Wrong input please enter correct input",0
    ErrAuthFailed      BYTE "Incorrect Details",0
    ErrInsufficient    BYTE "Not enough money",0
    MsgDepositSuccess  BYTE "Amount Deposited",0
    MsgWithdrawSuccess BYTE " ",10,"Amount Withdrawed",0
    MsgUserCreated     BYTE "User Created",0
    
    ; --- Output Labels ---
    LblCustomer        BYTE "Customer:   ",0
    LblAmount          BYTE "Amount:      ",0

    ; --- File Names ---
    FilenameUser       BYTE "user.txt",0
    FilenamePass       BYTE "password.txt",0
    FilenameMoney      BYTE "moneyfile.txt",0
    FileHandle         DWORD ?

    ; --- Input Buffers & Variables ---
    InputUsername      BYTE 20 DUP (?)
    StoredUsername     BYTE 20 DUP (?)
    UserSizeIn         DWORD ?
    UserSizeStore      DWORD ?

    InputPassword      BYTE 20 DUP (?)
    StoredPassword     BYTE 20 DUP (?)
    PassSizeIn         DWORD ?
    PassSizeStore      DWORD ?

    ; --- Financial Data ---
    BalanceBufferIn    BYTE 20 DUP (?)     ; amount1
    BalanceBufferOut   BYTE 20 DUP (?)     ; amount2
    BalanceSizeIn      DWORD ?             ; amountsize1
    CurrentBalanceInt  DWORD ?             ; amount (The integer value)

.code

main PROC

    ; Set text color to cyan on black (Yellow + Black*16 in original logic)
    mov  eax, cyan + (black * 16)
    call SetTextColor

    ; Display welcome message
    call Crlf
    call Crlf
    call Crlf
    mov  edx, OFFSET MsgWelcome
    call WriteString
    call Crlf
    call Crlf

MainMenuLoop:
    call Crlf
    call Crlf

    ; Display menu
    mov  edx, OFFSET MsgMainMenu
    call WriteString
    call Crlf
    call Crlf

    ; Read user input
    call ReadDec

    cmp  eax, 2
    je   LoginRoutine        ; Existing customer

    cmp  eax, 1
    je   NewUserRoutine      ; New user

    cmp  eax, 3
    je   ExitProgram         ; Exit

    ; Error handling
    call Crlf
    call Crlf
    mov  edx, OFFSET ErrInvalidInput
    call WriteString
    call Crlf
    call Crlf
    jmp  MainMenuLoop

ExitProgram:
    call Crlf
    call Crlf
    mov  edx, OFFSET EndingClause
    call WriteString
    call Crlf
    exit

; ---------------------------------------------------------
; Login Routine (Option 2)
; ---------------------------------------------------------
LoginRoutine:
    ; Prompt for username
    mov  edx, OFFSET PromptUsername
    call WriteString

    ; Read username input
    mov  edx, OFFSET InputUsername
    mov  ecx, SIZEOF InputUsername
    call ReadString
    mov UserSizeIn, eax
    call Crlf

    ; Prompt for password
    mov  edx, OFFSET PromptPassword
    call WriteString

    ; Read password input
    mov  edx, OFFSET InputPassword
    mov  ecx, SIZEOF InputPassword
    call ReadString
    mov PassSizeIn, eax

    ; Open user file for input
    mov  edx, OFFSET FilenameUser
    call OpenInputFile
    mov FileHandle, eax

    ; Read stored username
    mov  edx, OFFSET StoredUsername
    mov  ecx, LENGTHOF StoredUsername
    call ReadFromFile

    mov eax, FileHandle
    call CloseFile

    ; Open password file for input
    mov  edx, OFFSET FilenamePass
    call OpenInputFile
    mov FileHandle, eax

    ; Read stored password
    mov  edx, OFFSET StoredPassword
    mov  ecx, LENGTHOF StoredPassword
    call ReadFromFile
    mov PassSizeStore, eax

    mov eax, FileHandle
    call CloseFile

    ; --- Verify Credentials ---
    
    ; Compare Username sizes
    mov  ecx, UserSizeIn
    cmp  ecx, UserSizeStore
    jne  AuthFailed

    mov  esi, 0
Compare_Usernames:
    mov  al, InputUsername[esi]
    cmp  al, StoredUsername[esi]
    jne  AuthFailed
    inc  esi
    loop Compare_Usernames

    ; Compare Password sizes
    mov  ecx, PassSizeIn
    cmp  ecx, PassSizeStore
    jne  AuthFailed

    mov  esi, 0
Compare_Passwords:
    mov  al, InputPassword[esi]
    cmp  al, StoredPassword[esi]
    jne  AuthFailed
    inc  esi
    loop Compare_Passwords

    ; If success, jump to loading balance
    jmp  LoadBalance

AuthFailed:
    call Crlf
    mov  edx, OFFSET ErrAuthFailed
    call WriteString
    call Crlf
    jmp  MainMenuLoop

; ---------------------------------------------------------
; New User Routine (Option 1)
; ---------------------------------------------------------
NewUserRoutine:
    call Crlf

    ; Prompt for username
    mov  edx, OFFSET PromptUsername
    call WriteString

    ; Read new username
    mov  edx, OFFSET InputUsername
    mov  ecx, SIZEOF InputUsername
    call ReadString
    mov UserSizeIn, eax
    call Crlf

    ; Prompt for password
    mov  edx, OFFSET PromptPassword
    call WriteString

    ; Read new password
    mov  edx, OFFSET InputPassword
    mov  ecx, SIZEOF InputPassword
    call ReadString
    mov PassSizeIn, eax
    call Crlf

    ; Save Username to file
    mov  edx, OFFSET FilenameUser
    call CreateOutputFile
    mov FileHandle, eax
    mov  edx, OFFSET InputUsername
    mov  ecx, UserSizeIn
    call WriteToFile
    mov eax, FileHandle
    call CloseFile

    ; Save Password to file
    mov  edx, OFFSET FilenamePass
    call CreateOutputFile
    mov FileHandle, eax
    mov  edx, OFFSET InputPassword
    mov  ecx, PassSizeIn
    call WriteToFile
    mov eax, FileHandle
    call CloseFile

    ; Confirm creation
    mov  edx, OFFSET MsgUserCreated
    call WriteString
    call Crlf

    ; Prompt starting amount
    mov  edx, OFFSET PromptStartAmt
    call WriteString

    ; Read starting amount
    mov  edx, OFFSET BalanceBufferIn
    mov  ecx, SIZEOF BalanceBufferIn
    call ReadString

    jmp  ProcessBalanceString

; ---------------------------------------------------------
; Banking Operations
; ---------------------------------------------------------
LoadBalance:
    ; Open money file
    mov  edx, OFFSET FilenameMoney
    call OpenInputFile
    mov  FileHandle, eax

    ; Read balance string
    mov  edx, OFFSET BalanceBufferIn
    mov  ecx, LENGTHOF BalanceBufferIn
    call ReadFromFile

    ; Close file
    mov  eax, FileHandle
    call CloseFile

ProcessBalanceString:
    ; Find actual length of the balance string
    mov  esi, 0
    mov  ecx, LENGTHOF BalanceBufferIn

CalcLen_Balance:
    mov  al, BalanceBufferIn[esi]
    cmp  al, 0
    je   EndCalc_Balance
    inc  esi
    loop CalcLen_Balance

EndCalc_Balance:
    mov  eax, LENGTHOF BalanceBufferIn
    sub  eax, ecx
    mov  BalanceSizeIn, eax

    ; Convert String to Integer
    mov  eax, 0
    mov  esi, 0
    mov  ecx, BalanceSizeIn

    cmp ecx, 0
    je SaveInteger

StrToInt_Loop:
    movzx ebx, BalanceBufferIn[esi]
    sub   ebx, '0'
    mov   edx, 10
    mul   edx
    add   eax, ebx
    inc   esi
    loop  StrToInt_Loop

    ; Save integer balance
SaveInteger:
    mov  CurrentBalanceInt, eax

    mov  edx, OFFSET PromptTransact
    call WriteString
    call Crlf

TransactionLoop:
    call Crlf
    mov  edx, OFFSET MsgTransaction
    call WriteString
    call Crlf

    call ReadDec

    cmp  eax, 1
    je   ActionDeposit
    cmp  eax, 2
    je   ActionWithdraw
    cmp  eax, 3
    je   ActionShowBalance
    cmp  eax, 4
    je   ActionSaveAndQuit

    jmp TransactionLoop

; -- Deposit Logic --
ActionDeposit:
    call Crlf
    mov  edx, OFFSET PromptDeposit
    call WriteString
    call ReadDec
    add  CurrentBalanceInt, eax
    jmp  TransactionLoop

    ; -- Withdrawal Error --
ErrInsufficientFunds:
    mov  edx, OFFSET ErrInsufficient
    call WriteString
    call Crlf
    jmp  TransactionLoop

    ; -- Withdraw Logic --
ActionWithdraw:
    call Crlf
    mov  edx, OFFSET PromptWithdraw
    call WriteString
    call ReadDec
    cmp  eax, CurrentBalanceInt
    jnbe ErrInsufficientFunds   ; Jump if not enough money
    sub  CurrentBalanceInt, eax
    mov  edx, OFFSET MsgWithdrawSuccess
    call WriteString
    call Crlf
    jmp  TransactionLoop

    ; -- Show Balance Logic --
ActionShowBalance:
    mov edx, OFFSET LblAmount
    call WriteString
    mov  eax, CurrentBalanceInt
    call WriteDec
    call Crlf
    jmp  TransactionLoop

    ; -- Save and Quit Logic --
ActionSaveAndQuit:
    call Crlf
    
    ; Display User Details
    mov  edx, OFFSET LblCustomer
    call WriteString
    mov  edx, OFFSET InputUsername
    call WriteString
    call Crlf

    mov  edx, OFFSET LblAmount
    call WriteString
    mov  eax, CurrentBalanceInt
    call WriteDec
    call Crlf

    ; Convert Integer back to String
    mov  esi, 0
    mov  eax, CurrentBalanceInt
    
    cmp eax, 0
    jne IntToStr_Start

    mov BalanceBufferIn[0], '0'
    mov BalanceSizeIn, 1
    jmp WriteData

IntToStr_Start:
IntToStr_Loop:
    mov  edx, 0
    mov  ebx, 10
    div  ebx
    add  dl, '0'
    mov  BalanceBufferIn[esi], dl
    inc  esi

    cmp eax, 0
    jne IntToStr_Loop

    mov BalanceSizeIn, esi

    ; Reverse the string
    mov ecx, BalanceSizeIn
    mov esi, 0
    mov edi, BalanceSizeIn
    dec edi

ReverseStringLoop:
    mov  al, BalanceBufferIn[esi]
    mov  BalanceBufferOut[edi], al
    inc  esi
    dec  edi
    loop ReverseStringLoop

    ; Write updated balance to file
WriteData:
    call Crlf
    mov edx, OFFSET EndingClause
    call WriteString
    call Crlf

    mov  edx, OFFSET FilenameMoney
    call CreateOutputFile
    mov  FileHandle, eax

    mov  edx, OFFSET BalanceBufferOut

    cmp CurrentBalanceInt, 0
    jne DoWrite
    mov edx, OFFSET BalanceBufferIn

DoWrite:
    mov ecx, BalanceSizeIn
    call WriteToFile

    mov eax, FileHandle
    call CloseFile

    exit
main ENDP
END main
