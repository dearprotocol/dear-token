// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

// File: @openzeppelin/contracts/utils/Context.sol

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract VestingContract is Ownable{

    IERC20 public token = IERC20(address(0));
    uint[] public vestingSchedule;
    uint public totalClaims;
    uint public releasePerSchedule = 0;
    uint public lastClaimSchedule = 0;
    address public foundersWallet = address(0);
    bool initialized = false;
    mapping(uint => bool) public isClaimed;

    event Vested(address indexed wallet, uint indexed schedule, uint amount);
    constructor()
    Ownable(_msgSender()){

    }

    function initVesting(address token_,uint endTime_, uint totalClaims_,uint totalAmount,address _founderWallet) public onlyOwner{
        if(initialized) revert("already initialized");

        token = IERC20(token_);
        if(token.balanceOf(address(this)) < totalAmount) {
            revert("not enough tokens");
        }
        if(endTime_ < block.timestamp){
            revert("time is past");
        }
        // Assign Token
        _getVestingTimestampArray(endTime_, totalClaims_);
        totalClaims = totalClaims_;
        releasePerSchedule = totalAmount / totalClaims_;
        foundersWallet = _founderWallet;
        initialized = true;
    }   

    function _getVestingTimestampArray(uint endTime_, uint totalClaims_) private{
        uint startTime = block.timestamp;
        uint availableSeconds = endTime_ - startTime;
        uint waitTime = availableSeconds / totalClaims_;
        for(uint i=1; i <= totalClaims_; i++){
            uint next = (i * waitTime) + startTime;
            vestingSchedule.push(next);
        }
    }
    function getTimestamp() public view returns(uint){
        return block.timestamp;
    }
    function claim() public{
        uint currentClaimIndex = getClaimId();
        if(currentClaimIndex != 0 && lastClaimSchedule < currentClaimIndex){
            uint claimableLength = currentClaimIndex - lastClaimSchedule;
            if(claimableLength >= 5){
                _claimTokens(lastClaimSchedule,5);
                lastClaimSchedule += 5;
            }else{
                _claimTokens(lastClaimSchedule,claimableLength);
                lastClaimSchedule += claimableLength;
            }
        }else{
            revert("nothing to claim");
        }
    }
    
    function _claimTokens(uint startFromIndex,uint length) private {

        for(uint i = startFromIndex;i<startFromIndex+length;i++){
            if(isClaimed[i]) revert("already claimed!");
            isClaimed[i] = true;
            emit Vested(foundersWallet,i,releasePerSchedule);
        }
        uint totalTokenAvailable  = length * releasePerSchedule;
        token.transfer(foundersWallet, totalTokenAvailable);
    }

    function getClaimId() public view returns(uint) {
        for(uint i = 0; i < totalClaims; i++){
            if(vestingSchedule[i] > block.timestamp){
                return i;
            }
        }
        return totalClaims;
    }
    
}
