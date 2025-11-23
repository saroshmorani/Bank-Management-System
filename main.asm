INCLUDE Irvine32.inc

.data
    ; UI Strings & Messages
    EndingClause       BYTE "Bank Management System - Session Ended",0
    MsgWelcome         BYTE "***************************************** Multi-User Banking System  ****************************************",0
    MsgMainMenu        BYTE "Press 1 for New User",10,"Press 2 for Existing customer",10,"Press 3 to exit",0
    MsgTransaction     BYTE "Press 1 for Deposit",10,"Press 2 for Withdrawal",10,"Press 3 to Show Balance",10,"Press 4 to Log Out",0
    
    ; Prompts
    PromptUsername     BYTE "Enter username: ",0
    PromptPassword     BYTE "Enter Password: ",0
    PromptStartAmt     BYTE "Enter Starting Amount: ",0
    PromptWithdraw     BYTE "Enter Withdrawal Amount: ",0
    PromptDeposit      BYTE "Enter Deposit Amount: ",0
    PromptTransact     BYTE "Choose any transaction: ",0

    ; Status & Error Messages 
    ErrInvalidInput    BYTE "Invalid input.",0
    ErrAuthFailed      BYTE "Login Failed: Incorrect Username or Password.",0
    ErrUserNotFound    BYTE "Error: User does not exist.",0
    ErrUserExists      BYTE "Error: User already exists!",0
    ErrInsufficient    BYTE "Transaction Failed: Insufficient funds.",0
    MsgDepositSuccess  BYTE "Amount Deposited Successfully.",0
    MsgWithdrawSuccess BYTE "Amount Withdrawn Successfully.",0
    MsgUserCreated     BYTE "New User Account Created Successfully.",0
    MsgDBSaved         BYTE "Database updated.",0
    
    ; Output Labels
    LblCustomer        BYTE "Customer:    ",0
    LblAmount          BYTE "Balance:     ",0

    ; Database Constants & Variables
    FilenameDB         BYTE "bank_db.txt",0
    FileHandle         DWORD ?
    
    ; We use a large buffer to hold the entire file in memory
    ; Record Format: User(20) + Pass(20) + Balance(20) + CRLF(2) = 62 bytes (approx 64 for alignment)
    REC_SIZE           EQU 62
    NAME_SIZE          EQU 20
    PASS_SIZE          EQU 20
    BAL_SIZE           EQU 20
    
    FileBuffer         BYTE 20000 DUP(0)  ; Can store approx 300 users
    TotalBytes         DWORD 0            ; How many bytes are currently in the buffer
    CurrentRecordPtr   DWORD 0            ; Pointer to the start of the logged-in user's record in the buffer

    ; Input/Temp Buffers
    InputUsername      BYTE 21 DUP(0)
    InputPassword      BYTE 21 DUP(0)
    InputBalance       BYTE 21 DUP(0)
    
    ; Temporary buffer for parsing strings
    TempString         BYTE 21 DUP(0)

    CurrentBalanceInt  DWORD ?

.code

; Procedure: LoadDatabase
; Reads the entire 'bank_db.txt' into FileBuffer
LoadDatabase PROC
    ; Open file for reading
    mov  edx, OFFSET FilenameDB
    call OpenInputFile
    cmp  eax, INVALID_HANDLE_VALUE
    je   NoFileFound
    
    mov  FileHandle, eax
    
    ; Read content
    mov  edx, OFFSET FileBuffer
    mov  ecx, SIZEOF FileBuffer
    call ReadFromFile
    mov  TotalBytes, eax    ; Store total size read
    
    mov  eax, FileHandle
    call CloseFile
    ret

NoFileFound:
    ; If file doesn't exist, TotalBytes stays 0
    mov TotalBytes, 0
    ret
LoadDatabase ENDP

; Procedure: SaveDatabase
; Writes the entire FileBuffer back to 'bank_db.txt'
SaveDatabase PROC
    ; Create or Overwrite file
    mov  edx, OFFSET FilenameDB
    call CreateOutputFile
    mov  FileHandle, eax
    
    ; Write content
    mov  edx, OFFSET FileBuffer
    mov  ecx, TotalBytes
    call WriteToFile
    
    mov  eax, FileHandle
    call CloseFile
    ret
SaveDatabase ENDP

; Procedure: PadString
; Fills the destination with the source string, then pads
; the rest with spaces up to ECX length.
; Input: ESI = Source String, EDI = Dest in Buffer, ECX = Field Size
PadString PROC USES eax esi edi ecx
    ; Copy string
CopyLoop:
    mov  al, [esi]
    cmp  al, 0
    je   StartPadding
    mov  [edi], al
    inc  esi
    inc  edi
    dec  ecx
    cmp  ecx, 0
    je   Done
    jmp  CopyLoop

StartPadding:
    ; Fill remainder with spaces
    cmp  ecx, 0
    je   Done
    mov  byte ptr [edi], ' '
    inc  edi
    loop StartPadding

Done:
    ret
PadString ENDP

; Procedure: ParsePaddedInt
; Reads a space-padded string from buffer and converts to Int
; Input: ESI = Pointer to start of number in FileBuffer
; Output: EAX = Integer value
ParsePaddedInt PROC USES ecx edx esi edi
    ; Copy valid digits to TempString
    mov  edi, OFFSET TempString
    mov  ecx, BAL_SIZE
    
ParseCopy:
    mov  al, [esi]
    cmp  al, ' '        ; Stop at space
    je   DoConvert
    cmp  al, 13         ; Stop at CR
    je   DoConvert
    mov  [edi], al
    inc  esi
    inc  edi
    loop ParseCopy

DoConvert:
    mov  byte ptr [edi], 0  ; Null terminate
    
    ; Convert TempString to Int (Manual Logic)
    mov  edx, OFFSET TempString
    mov  ecx, 0 ; Accumulator
    mov  esi, 0
    
ConvertLoop:
    movzx eax, byte ptr TempString[esi]
    cmp   al, 0
    je    FinishedConvert
    sub   al, '0'
    imul  ecx, 10
    add   ecx, eax
    inc   esi
    jmp   ConvertLoop

FinishedConvert:
    mov eax, ecx
    ret
ParsePaddedInt ENDP

; MAIN PROGRAM
main PROC
    mov  eax, cyan + (black * 16)
    call SetTextColor

    ; Load Data on startup
    call LoadDatabase

    call Crlf
    mov  edx, OFFSET MsgWelcome
    call WriteString
    call Crlf

MainMenuLoop:
    call Crlf
    mov  edx, OFFSET MsgMainMenu
    call WriteString
    call Crlf
    call Crlf

    call ReadDec
    
    cmp  eax, 1
    je   NewUserRoutine
    cmp  eax, 2
    je   LoginRoutine
    cmp  eax, 3
    je   ExitProgram
    
    mov  edx, OFFSET ErrInvalidInput
    call WriteString
    call Crlf
    jmp  MainMenuLoop

ExitProgram:
    call Crlf
    mov  edx, OFFSET EndingClause
    call WriteString
    exit

; Login Routine
LoginRoutine:
    call Crlf
    ; Get Username
    mov  edx, OFFSET PromptUsername
    call WriteString
    mov  edx, OFFSET InputUsername
    mov  ecx, SIZEOF InputUsername
    call ReadString

    ; Get Password
    mov  edx, OFFSET PromptPassword
    call WriteString
    mov  edx, OFFSET InputPassword
    mov  ecx, SIZEOF InputPassword
    call ReadString
    
    ; --- Scan Memory Buffer for User ---
    mov  esi, OFFSET FileBuffer
    mov  ecx, TotalBytes
    cmp  ecx, 0
    je   UserNotFound     ; Empty DB

ScanLoop:
    cmp  ecx, REC_SIZE
    jl   UserNotFound     ; Less than one record left
    
    push esi              ; Save start of current record
    push ecx              ; Save counter

    ; Compare Username (First 20 bytes of record)
    ; Check if Buffer starts with InputUsername string
    mov  edi, OFFSET InputUsername
    mov  ebx, esi         ; EBX = Record Start
    
CheckUser:
    mov  al, [edi]
    cmp  al, 0
    je   CheckPad         ; End of input, check if buffer has space
    cmp  al, [ebx]
    jne  NextRecord       ; Mismatch
    inc  edi
    inc  ebx
    jmp  CheckUser

CheckPad:
    ; Ensure the buffer has a space here (exact match, not substring)
    mov  al, [ebx]
    cmp  al, ' '
    jne  NextRecord

    ; User Matched, Check Password (Offset 20)
    pop  ecx
    pop  esi
    push esi
    push ecx
    
    mov  ebx, esi
    add  ebx, NAME_SIZE   ; Move to password field
    mov  edi, OFFSET InputPassword
    
CheckPass:
    mov  al, [edi]
    cmp  al, 0
    je   CheckPassPad
    cmp  al, [ebx]
    jne  NextRecord
    inc  edi
    inc  ebx
    jmp  CheckPass

CheckPassPad:
    mov  al, [ebx]
    cmp  al, ' '
    jne  NextRecord
    
    ; Match Found
    pop  ecx
    pop  esi      ; ESI is the start of the record
    mov  CurrentRecordPtr, esi
    
    ; Parse Balance (Offset 40)
    add  esi, NAME_SIZE
    add  esi, PASS_SIZE   ; ESI points to Balance
    call ParsePaddedInt
    mov  CurrentBalanceInt, eax
    
    jmp  TransactionLoop

NextRecord:
    pop  ecx
    pop  esi
    add  esi, REC_SIZE
    sub  ecx, REC_SIZE
    jmp  ScanLoop

UserNotFound:
    mov  edx, OFFSET ErrAuthFailed
    call WriteString
    call Crlf
    jmp  MainMenuLoop

; New User Routine
NewUserRoutine:
    call Crlf
    ; Get Data
    mov  edx, OFFSET PromptUsername
    call WriteString
    mov  edx, OFFSET InputUsername
    mov  ecx, 15
    call ReadString
    
    ; Check duplicates (Just scan username)
    mov  esi, OFFSET FileBuffer
    mov  ecx, TotalBytes
    
CheckDupLoop:
    cmp  ecx, REC_SIZE
    jl   CreateUser       ; End of list, safe to create
    
    push esi
    push ecx
    
    mov  edi, OFFSET InputUsername
    mov  ebx, esi
CheckDupName:
    mov  al, [edi]
    cmp  al, 0
    je   CheckDupPad
    cmp  al, [ebx]
    jne  NextDup
    inc  edi
    inc  ebx
    jmp  CheckDupName
    
CheckDupPad:
    mov  al, [ebx]
    cmp  al, ' '
    jne  NextDup
    
    ; Found duplicate
    pop  ecx
    pop  esi
    mov  edx, OFFSET ErrUserExists
    call WriteString
    call Crlf
    jmp  MainMenuLoop

NextDup:
    pop  ecx
    pop  esi
    add  esi, REC_SIZE
    sub  ecx, REC_SIZE
    jmp  CheckDupLoop

CreateUser:
    ; Get Password
    mov  edx, OFFSET PromptPassword
    call WriteString
    mov  edx, OFFSET InputPassword
    mov  ecx, 15
    call ReadString
    
    ; Get Balance
    mov  edx, OFFSET PromptStartAmt
    call WriteString
    mov  edx, OFFSET InputBalance
    mov  ecx, 15
    call ReadString
    
    ; Append to Memory Buffer
    mov  edi, OFFSET FileBuffer
    add  edi, TotalBytes      ; Point to end of data
    
    ; 1. Write Username (20 bytes)
    mov  esi, OFFSET InputUsername
    mov  ecx, NAME_SIZE
    call PadString
    
    add  edi, NAME_SIZE
    
    ; 2. Write Password (20 bytes)
    mov  esi, OFFSET InputPassword
    mov  ecx, PASS_SIZE
    call PadString
    
    add  edi, PASS_SIZE
    
    ; 3. Write Balance (20 bytes)
    mov  esi, OFFSET InputBalance
    mov  ecx, BAL_SIZE
    call PadString
    
    add  edi, BAL_SIZE
    
    ; 4. Write CRLF
    mov  byte ptr [edi], 13
    inc  edi
    mov  byte ptr [edi], 10
    inc  edi
    
    ; Update Total Size
    add  TotalBytes, REC_SIZE
    
    ; Save to Disk
    call SaveDatabase
    
    mov  edx, OFFSET MsgUserCreated
    call WriteString
    call Crlf
    
    ; Auto Login logic: Set CurrentRecordPtr to the new record
    mov  eax, OFFSET FileBuffer
    add  eax, TotalBytes
    sub  eax, REC_SIZE
    mov  CurrentRecordPtr, eax
    
    ; Parse the balance (to get int value)
    mov  esi, OFFSET InputBalance
    
    mov  edx, OFFSET InputBalance
    call ParseStringToInt
    
    jmp  MainMenuLoop

ParseStringToInt:
    ; Simple helper for the initial balance input
    mov  ecx, 0
    mov  esi, edx
Ploop:
    movzx eax, byte ptr [esi]
    cmp   al, 0
    je    Pdone
    sub   al, '0'
    imul  ecx, 10
    add   ecx, eax
    inc   esi
    jmp   Ploop
Pdone:
    mov CurrentBalanceInt, ecx
    ret

; Banking Operations
TransactionLoop:
    call Crlf
    mov  edx, OFFSET LblCustomer
    call WriteString
    mov  edx, OFFSET InputUsername
    call WriteString
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
    je   ActionLogout

    jmp TransactionLoop

ActionDeposit:
    call Crlf
    mov  edx, OFFSET PromptDeposit
    call WriteString
    call ReadDec
    add  CurrentBalanceInt, eax
    call UpdateBalanceRecord
    mov  edx, OFFSET MsgDepositSuccess
    call WriteString
    call Crlf
    jmp  TransactionLoop

ActionWithdraw:
    call Crlf
    mov  edx, OFFSET PromptWithdraw
    call WriteString
    call ReadDec
    cmp  eax, CurrentBalanceInt
    jnbe ErrInsufficientFunds
    
    sub  CurrentBalanceInt, eax
    call UpdateBalanceRecord
    mov  edx, OFFSET MsgWithdrawSuccess
    call WriteString
    call Crlf
    jmp  TransactionLoop

ErrInsufficientFunds:
    mov  edx, OFFSET ErrInsufficient
    call WriteString
    call Crlf
    jmp  TransactionLoop

ActionShowBalance:
    call Crlf
    mov edx, OFFSET LblAmount
    call WriteString
    mov  eax, CurrentBalanceInt
    call WriteDec
    call Crlf
    jmp  TransactionLoop

ActionLogout:
    jmp MainMenuLoop

; Helper: UpdateBalanceRecord
; Converts CurrentBalanceInt to string and updates FileBuffer
UpdateBalanceRecord PROC
    ; 1. Convert Int to String in TempString
    mov  eax, CurrentBalanceInt
    mov  ecx, 0
    mov  edi, OFFSET TempString
    add  edi, 19        ; Start at end of buffer
    mov  byte ptr [edi], 0
    dec  edi
    
    cmp  eax, 0
    jne  ConvertInt
    mov  byte ptr [edi], '0'
    dec  edi
    jmp  WriteToBuff

ConvertInt:
    mov  ebx, 10
DivLoop:
    mov  edx, 0
    div  ebx
    add  dl, '0'
    mov  [edi], dl
    dec  edi
    cmp  eax, 0
    jne  DivLoop

WriteToBuff:
    inc  edi            ; Points to start of number string
    mov  esi, edi       ; Source is TempString
    
    ; Destination is CurrentRecordPtr + NAME + PASS
    mov  edi, CurrentRecordPtr
    add  edi, NAME_SIZE
    add  edi, PASS_SIZE
    
    ; Write and Pad
    mov  ecx, BAL_SIZE
    call PadString
    
    ; Save to Disk immediately
    call SaveDatabase
    ret
UpdateBalanceRecord ENDP

main ENDP
END main
