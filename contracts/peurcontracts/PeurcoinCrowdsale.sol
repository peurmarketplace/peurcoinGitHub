/**
 *  The Peurcoin token contract complies with the ERC20 standard (see https://github.com/ethereum/EIPs/issues/20).
 *  The owner's shareholder of tokens is locked for three year and not all tokens
 *  being sold during or after the crowdsale,reserved token will be use only for loyalty program.
 *  Author: Nancy Abrianna
 *  Internal audit: Felix Norge, John Dewitt
 *  Audit: Smart Contract Consultant
 **/

pragma solidity ^0.4.15;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) returns (bool) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

contract Ownable {
  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

contract PeurCrowdsale is Ownable, StandardToken {

  string public constant name = "Peurcoin";
  string public constant symbol = "PURC";
  uint public constant decimals = 8;
  // replace with your fund collection multisig address
  address public constant multisig = "0xbb6f20a6358324cC12e9ff7bC0514dDDd1e1a167";


  // 1 ether = 8000 example tokens phase one
  uint public constant PRICE = 8000;

  /**
   * @dev Fallback function which receives ether and sends the appropriate number of tokens to the 
   * msg.sender.
   */
  function () payable {
    createTokens(msg.sender);
  }

  /**
   * @dev initial tokens and send to the specified address.
   * @param recipient The address which will recieve the new tokens.
   */
  function initialTokens(address recipient) payable {
    if (msg.value == 0) {
      throw;
    }

    uint tokens = msg.value.mul(getPrice());
    totalSupply = totalSupply.sub(tokens);

    balances[recipient] = balances[recipient].sub(tokens);

    if (!multisig.send(msg.value)) {
      throw;
    }
  }

  /**
   * @dev replace this with any other price function
   * @return The price per unit of token. 
   */
  function getPrice() constant returns (uint result) {
    return PRICE;
  }
}

/**
 * 130.000.000 PURC tokens distributed for ICO 
 *  42.300.000 PURC tokens distributed for loyalty program
 *  17.500.000 PURC tokens distributed for peur marketplace department
 *   5.200.000 PURC tokens distributed for bounty campaign
 *   5.000.000 PURC tokens distributed for shareholder
 * Overall, 200.000.000 PURC tokens fixed supply 
 * All crowdsale depositors must have read the legal agreement.
 * They give their crowdsale Ethereum source address on the website.
 * This is confirmed by having them signing the terms of service on the website.
*/