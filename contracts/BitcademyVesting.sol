pragma solidity ^0.4.23;

import "./BitcademyToken.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";


/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * owner.
 */
contract BitcademyVesting is Ownable {
  using SafeMath for uint256;

  event Released(uint256 amount);

  uint256 public cliff;
  uint256 public start;
  uint256 public duration;
  uint256 public interval;
  uint    public countRelease = 0;
  uint256 public ReleaseCap = 150000000000000000000000000;
  mapping (address=>bool) public members;
  mapping (address =>uint) public numReleases;
  mapping (address => uint) public nextRelease;
  uint256 public noOfMembers;
  uint256 public released;
  //uint256 public standardQuantity;
  uint public constant Releases = 18;
  /**
   * @dev Creates a vesting contract that vests its balance of any BitcademyToken token to the
   * _beneficiary, gradually in a linear fashion until _start + _duration. By then all
   * of the balance will have vested.
   * @param _cliff duration in seconds of the cliff in which tokens will begin to vest
   * @param _start the time (as Unix time) at which point vesting starts
   * @param _duration duration in seconds of the period in which the tokens will vest
   */
  constructor(
    uint256 _start,
    uint256 _cliff,
    uint256 _duration,
    uint256 _interval
  )
    public
  {

    require(_start > now);
    require(_cliff > 0);
    require(_duration > 0);
    require(_interval > 0);
    require(_cliff <= _duration);


    duration = _duration;
    cliff = _start.add(_cliff);
    start = _start;
    interval = _interval;
  }

  modifier onlyMember(address _memberAddress) {
    require(members[_memberAddress] == true);
      _;
  }

  function addMember(address _member) public onlyOwner {
      require(_member != address(0));
      require(members[_member] == false);
      require(countRelease <= 0);
      members[_member] = true;
      noOfMembers = noOfMembers.add(1);
  }

  function removeMember(address _member) public onlyOwner {
      require(_member != address(0));
      require(members[_member] == true);
      require(countRelease <= 0);
      members[_member] = false;
      noOfMembers = noOfMembers.sub(1);
  }

  /**
   * @notice Transfers vested tokens to beneficiary.
   * @param _token BitcademyToken token which is being vested
   */
  function release(BitcademyToken _token, address _member) onlyMember(_member) public {
     require (block.timestamp > cliff);
     uint256 releasableToken = _token.balanceOf(this);
     uint256 unreleased = 0;

    require(releasableToken > 0);

    require(numReleases[_member] <= Releases);
    if (numReleases[_member] == 0){
    require(block.timestamp >= interval.add(cliff));
     unreleased = ReleaseCap.div(noOfMembers.mul(Releases));
     released = released.add(unreleased);
     //unreleased =  unreleased.div(noOfMembers);
     _token.transfer(_member, unreleased);
     numReleases[_member] = numReleases[_member].add(1);
     nextRelease[_member] = interval.add(cliff).add(interval);
     countRelease = countRelease + 1;
   }
   else if (numReleases[_member] > 0){
     require(block.timestamp >= nextRelease[_member] );
     released = released.add(unreleased);
     unreleased = ReleaseCap.div(noOfMembers.mul(Releases));
     //unreleased =  unreleased.div(noOfMembers);
     _token.transfer(_member, unreleased);
     numReleases[_member] = numReleases[_member].add(1);
     nextRelease[_member] = nextRelease[_member].add(interval);
     countRelease = countRelease + 1;
   }

    emit Released(unreleased);
  }


}
