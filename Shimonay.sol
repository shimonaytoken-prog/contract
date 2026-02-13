/**
 *Submitted for verification at BscScan.com on 2026-01-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Shimonay is IBEP20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public immutable totalSupply;

    address public owner;

    /// Taxa desligada por padrão
    bool public taxEnabled = false;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    event TaxEnabledSet(bool enabled);

    /// Endereço de burn padrão
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    constructor() {
        name = "Shimonay";
        symbol = "SHIMO";
        decimals = 9;
        totalSupply = 200_000_000_000 * 10**9; // 200B tokens com 9 decimais


        owner = msg.sender;
        _balances[msg.sender] = totalSupply;

        emit Transfer(address(0), msg.sender, totalSupply);
    }

    // ---------------- VIEW ----------------

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address tokenOwner, address spender) public view override returns (uint256) {
        return _allowances[tokenOwner][spender];
    }

    // -------------- OWNER TAX CONTROL ----------------

    /// Liga ou desliga a taxa de burn
    function setTaxEnabled(bool enabled) external onlyOwner {
        taxEnabled = enabled;
        emit TaxEnabledSet(enabled);
    }

    // ---------------- CORE ----------------

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    // ---------------- INTERNAL ----------------

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "zero addr");
        require(recipient != address(0), "zero addr");
        require(amount > 0, "zero amount");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "balance");

        _balances[sender] = senderBalance - amount;

        if (taxEnabled) {
            // 3% tax (aproximado)
            uint256 burnAmount = amount / 33;
            uint256 receiveAmount = amount - burnAmount;

            // burn
            _balances[BURN_ADDRESS] += burnAmount;
            emit Transfer(sender, BURN_ADDRESS, burnAmount);

            // recipient
            _balances[recipient] += receiveAmount;
            emit Transfer(sender, recipient, receiveAmount);

        } else {
            // transferência normal SEM TAXA
            _balances[recipient] += amount;
            emit Transfer(sender, recipient, amount);
        }
    }

    function _approve(address tokenOwner, address spender, uint256 amount) internal {
        require(tokenOwner != address(0), "zero addr");
        require(spender != address(0), "zero addr");

        _allowances[tokenOwner][spender] = amount;
        emit Approval(tokenOwner, spender, amount);
    }
}
