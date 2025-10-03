//SPDX-License-Identifier: MIT 

pragma solidity 0.8.30;

/**
 * @title KipuBank
 * @author Erik Borgnia
 * @notice Contrato para el TP Final del Módulo 2 del curso de EthKipu
 * @notice Es una simulación de banco con depósitos y extracción, auditable por el dueño del contrato
 */
contract KipuBank{
    ///@notice Dueño del contrato, auditor del mismo
    address public immutable s_owner;
    ///@notice Mapping que mantienen el balance de las distintas cuentas
    mapping (address user => uint256 amount) s_balances;
    ///@notice Mapping que mantienen la cantidad de depósitos de las distintas cuentas
    mapping (address user => uint32 counter) s_deposits;
    ///@notice Mapping que mantienen la cantidad de extracciones de las distintas cuentas
    mapping (address user => uint32 counter) s_withdrawals;
    
    ///@notice Límite de balance por cuenta
    uint128 public immutable s_bankCap;
    ///@notice Límite de extracción por cuenta
    uint128 public immutable s_withdrawLimit = 1000000000000000000; //1.000.000.000.000.000.000
    // Que sean a lo mucho la mitad de lo máximo que podría tener el contrato es bastante razonable.
    //1 trillón (o 1 quintillions) necesita menos de 128 bits, pero por coherencia se lo deja uint128
    //Acomodado a un número más razonable. Es equivalente a 0.1 ETH.

    ///@notice Evento emitido al intentar depositar
    event DepositRequest(address from, uint amount);
    ///@notice Evento emitido al depositar exitosamente
    event Deposited(address from, uint amount);
    ///@notice Evento emitido al intentar extraer
    event ExtractionRequest(address to, uint amount);
    ///@notice Evento emitido al extraer exitosamente
    event Extracted(address to, uint amount);

    ///@notice Error emitido cuando se intenta depositar una cantidad inválida (=0, o la cuenta superaría el bankCap)
    error DepositNotAllowed(address to, uint amount);
    ///@notice Error emitido cuando se intenta extraer una cantidad inválda (<=0, >saldo, >límite)
    error ExtractionNotAllowed(address to, uint amount);
    ///@notice Error emitido cuando falla una extracción
    error ExtractionReverted(address to, uint amount, bytes errorData);
    ///@notice Error emitido al querer auditar y no tener el permiso
    error NotAnAuditor(address user);

    /*
        *@notice Constructor que recibe el bankCap como parámetro
        *@param _bankCap es el máximo que podría tener el contrato en total
    */
    constructor(uint128 _banckCap) {
        s_bankCap = _banckCap;
        s_owner = msg.sender;
    }

    /**
        *@notice Función receive para manejar depósitos directos
		*@notice Esto garantiza la consistencia con las interacciones del contrato
    */
    receive() external payable {
        deposit();
    }

    /**
        *@notice Función para hacer un depósito
		*@notice Sólo se puede depositar un valor mayor a 0, siempre que no se supere el bankCap
    */
    function deposit() public payable {
        emit DepositRequest(msg.sender, msg.value);
        require(msg.value > 0, DepositNotAllowed(msg.sender,msg.value));
        require(msg.value+s_balances[msg.sender] <= s_bankCap, DepositNotAllowed(msg.sender,msg.value));

        s_balances[msg.sender] += msg.value;
        s_deposits[msg.sender]++;
        
        emit Deposited(msg.sender, msg.value);
    }

    /**
        *@notice Función pública para ver el balance que uno mismo tiene
    */
    function getBalance() external view returns(uint balance_) {
        balance_ = s_balances[msg.sender];
    }
    /**
        *@notice Función pública para ver la cantidad de depósitos que uno hizo
    */
    function getDeposits() external view returns(uint deposits_) {
        deposits_ = s_deposits[msg.sender];
    }
    /**
        *@notice Función pública para ver la cantidad de extracciones que uno hizo
    */
    function getWithdrawals() external view returns(uint withdrawals_) {
        withdrawals_ = s_withdrawals[msg.sender];
    }

    /**
        *@notice Función pública para ver el balance que algún usuario tiene
		*@dev Esta función garantiza que toda la información es auditable
        *@param user_ Usuario que se quiere auditar
    */
    function getBalance(address user_) external view returns(uint balance_) {
        require(msg.sender==s_owner,NotAnAuditor(msg.sender));
        balance_ = s_balances[user_];
    }
    /**
        *@notice Función pública para ver la cantidad de depósitos que algún usuario hizo
		*@dev Esta función garantiza que toda la información es auditable
        *@param user_ Usuario que se quiere auditar
    */
    function getDeposits(address user_) external view returns(uint deposits_) {
        require(msg.sender==s_owner,NotAnAuditor(msg.sender));
        deposits_ = s_deposits[user_];
    }
    /**
        *@notice Función pública para ver la cantidad de extracciones que algún usuario hizo
		*@dev Esta función garantiza que toda la información es auditable
        *@param user_ Usuario que se quiere auditar
    */
    function getWithdrawals(address user_) external view returns(uint withdrawals_) {
        require(msg.sender==s_owner,NotAnAuditor(msg.sender));
        withdrawals_ = s_withdrawals[user_];
    }

    /**
        *@notice Función para hacer un depósito
		*@dev Sólo se puede depositar un valor mayor a 0, siempre que no se supere el bankCap
        *@param amount_ Cantidad que se quiere extraer. Debe ser <= al balance y al límite de extracción
    */
    function withdraw(uint amount_) public {
        emit ExtractionRequest(msg.sender, amount_);
        require(amount_ > 0, ExtractionNotAllowed(msg.sender, amount_));
        require(amount_ <= s_balances[msg.sender], ExtractionNotAllowed(msg.sender, amount_));
        require(amount_ <= s_withdrawLimit, ExtractionNotAllowed(msg.sender, amount_));

        s_balances[msg.sender] -= amount_;
        s_withdrawals[msg.sender]++;
        
        transferFunds(amount_);
        
        emit Extracted(msg.sender, amount_);        
    }

    /**
        *@notice Función privada que transfiere la cantidad pedida por la extracción
		*@dev Nadie puede acceder a esta función excepto ESTE contrato
        *@param amount_ Cantidad a transferir
    */
    function transferFunds(uint amount_) private {
        (bool success, bytes memory errorData) = msg.sender.call{value: amount_}("");
        require(success, ExtractionReverted(msg.sender,amount_,errorData));
    }


}