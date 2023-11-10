// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Payer Polygon
/// @author Bozz & Barba
/// @notice This contract is used to pay the prizes for the Raffles of the RaffleMyTrevo contract.
/// @dev This contract focuses on a single function to transfer prizes or verify that the prize has not been transferred to the winner and consequently change the status of the raffle to canceled.

/*                                                                      
    :----:                                                                  
  --.:  ..--     .:-..    .:..:     .....    ..   :     ::::.               
  =*:      .*=      -      :. .-     .....     :. -     -.   =               
  --..  ::--       -      :.  -     -:...      :-      .-:.::               
    :----:                                                                  
      ..                                                      
*/

contract PayerPolygon is Ownable {

  /// STRUCTS

  /// @dev The struct of a Raffle
  struct Raffle{
    uint256 id;
    address addressPrize;
    uint256 idPrize;
    uint256 randomNumberVRF;
    address winner;
    RaffleStatus status;
    address creator;
    uint256 amount;
    TokenType prizeTokenType;
  }

  /// ENUMS
  
  /// @dev Enums for the status of a raffle
  enum RaffleStatus{
    Paid, 
    Unpaid
  }

  /// @dev Enums for the type of a prize
  enum TokenType{
    ERC20,
    ERC721,
    ERC1155
  }

  /// EVENTS

  /// @dev Event triggered when a prize is transferred to the winner
  event paidRaffle(address indexed _creator, address indexed _winnerAddress, uint256 _winnerTicket, uint256 indexed _raffleId, address _addressPrize, uint256 _idPrize, uint256 _tokenType, uint256 _amount);
  
  /// @dev Event triggered when a prize is not transferred to the winner
  event unpaidRaffle(address indexed _creator, address indexed _winnerAddress, uint256 _winnerTicket, uint256 indexed _raffleId, address _addressPrize, uint256 _idPrize, uint256 _tokenType, uint256 _amount);

  /// MAPPINGS

  /// @dev Mapping of raffles by raffle ID
  mapping(uint256 => Raffle) public raffles;

  /// @dev Mapping for converting a number into a prize type
  mapping(uint256 => TokenType) public tokenIdToTokenType;

  /// CONSTRUCTOR
  
  constructor() payable{}

  /// FUNCTIONS

  /// @dev Internal function to convert a number into a Token Type
  /// @param _prizeTokenType number 0 || 1 || 2
  /// @return TokenType
  function convertToTokenType(uint256 _prizeTokenType) internal pure returns (TokenType) {
    require(_prizeTokenType >= 0 && _prizeTokenType <= 2, "Invalid prize token type value");

    if (_prizeTokenType == 0) {
      return TokenType.ERC20;
    } else if (_prizeTokenType == 1) {
      return TokenType.ERC721;
    } else {
      return TokenType.ERC1155;
    }
  }

  /// @dev Function for the contract owner to request the contract to attempt transferring the prize to the winner.
  /// @param _creator Address of the raffle creator
  /// @param _winnerAddress Address of the raffle winner
  /// @param _winnerTicket Winning raffle ticket number
  /// @param _raffleId Raffle ID
  /// @param _addressPrize Prize address
  /// @param _idPrize NFT Token ID. If it's ERC20, specify 1
  /// @param _prizeTokenType 0 = ERC20 || 1 = ERC721 || 2 = ERC1155
  /// @param _amount If the prize is an NFT, specify 1; if it's ERC20, provide the token amount with decimals included
  /// @return true = The contract successfully transferred the prize to the winner || false = The contract was unable to transfer the prize to the winner
  function payWinner(address _creator, address _winnerAddress, uint256 _winnerTicket, uint256 _raffleId, address _addressPrize, uint256 _idPrize, uint256 _prizeTokenType, uint256 _amount) external onlyOwner returns(bool) {
    require(_raffleId != 0, "Raffle does not exist");

    TokenType prizeTokenType = convertToTokenType(_prizeTokenType);

    if(prizeTokenType == TokenType.ERC721){

      IERC721 contractPrize = IERC721(_addressPrize);
  
      contractPrize.safeTransferFrom(_creator, _winnerAddress, _idPrize);

      if(_winnerAddress == contractPrize.ownerOf(_idPrize)){

        Raffle memory newRaffle = Raffle({
          id: _raffleId,
          addressPrize: _addressPrize,
          idPrize: _idPrize,
          randomNumberVRF: _winnerTicket,
          winner: _winnerAddress,
          status: RaffleStatus.Paid,
          creator: _creator,
          prizeTokenType: prizeTokenType,
          amount: _amount
        });

        raffles[_raffleId] = newRaffle;

        emit paidRaffle(_creator, _winnerAddress, _winnerTicket, _raffleId, _addressPrize, _idPrize, _prizeTokenType, _amount);

        return true;
      } else{

        Raffle memory newRaffle = Raffle({
          id: _raffleId,
          addressPrize: _addressPrize,
          idPrize: _idPrize,
          randomNumberVRF: _winnerTicket,
          winner: _winnerAddress,
          status: RaffleStatus.Unpaid,
          creator: _creator,
          prizeTokenType: prizeTokenType,
          amount: _amount
        });

        raffles[_raffleId] = newRaffle;

        emit unpaidRaffle(_creator, _winnerAddress, _winnerTicket, _raffleId, _addressPrize, _idPrize, _prizeTokenType, _amount);

        return false;
      }
    }else if (prizeTokenType == TokenType.ERC1155) {

      ERC1155 contractPrize1155 = ERC1155(_addressPrize);
      uint256 initialBalance = contractPrize1155.balanceOf(_winnerAddress, _idPrize);

      contractPrize1155.safeTransferFrom(_creator, _winnerAddress, _idPrize, 1, "0x00"); 

      uint256 finalBalance = contractPrize1155.balanceOf(_winnerAddress, _idPrize);

      if(finalBalance > initialBalance){

        Raffle memory newRaffle = Raffle({
          id: _raffleId,
          addressPrize: _addressPrize,
          idPrize: _idPrize,
          randomNumberVRF: _winnerTicket,
          winner: _winnerAddress,
          status: RaffleStatus.Paid,
          creator: _creator,
          prizeTokenType: prizeTokenType,
          amount: _amount
        });

        raffles[_raffleId] = newRaffle;

        emit paidRaffle(_creator, _winnerAddress, _winnerTicket, _raffleId, _addressPrize, _idPrize, _prizeTokenType, _amount);

        return true;
      }else {
        
        Raffle memory newRaffle = Raffle({
          id: _raffleId,
          addressPrize: _addressPrize,
          idPrize: _idPrize,
          randomNumberVRF: _winnerTicket,
          winner: _winnerAddress,
          status: RaffleStatus.Unpaid,
          creator: _creator,
          prizeTokenType: prizeTokenType,
          amount: _amount
        });

        raffles[_raffleId] = newRaffle;

        emit unpaidRaffle(_creator, _winnerAddress, _winnerTicket, _raffleId, _addressPrize, _idPrize, _prizeTokenType, _amount);

        return false;
      }
        
    }else if (prizeTokenType == TokenType.ERC20) {
        
      IERC20 contractPrize20 = IERC20(_addressPrize);
      bool success = false;

      if (
        contractPrize20.balanceOf(_creator) >= _amount &&
        contractPrize20.allowance(_creator, address(this)) >= _amount &&
        contractPrize20.transferFrom(_creator, _winnerAddress, _amount)
      ) {
        success = true;
      }

      Raffle memory newRaffle = Raffle({
        id: _raffleId,
        addressPrize: _addressPrize,
        idPrize: _idPrize,
        randomNumberVRF: _winnerTicket,
        winner: _winnerAddress,
        status: success ? RaffleStatus.Paid : RaffleStatus.Unpaid,
        creator: _creator,
        prizeTokenType: prizeTokenType,
        amount: _amount
      });

      raffles[_raffleId] = newRaffle;

      if (success) {
        emit paidRaffle(_creator, _winnerAddress, _winnerTicket, _raffleId, _addressPrize, _idPrize, _prizeTokenType, _amount);
      } else {
        emit unpaidRaffle(_creator, _winnerAddress, _winnerTicket, _raffleId, _addressPrize, _idPrize, _prizeTokenType, _amount);
      }

      return success;
    }

    return false;
  }

}