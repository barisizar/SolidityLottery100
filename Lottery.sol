// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Lottery Contract
 * @dev This contract allows users to participate in a lottery where they can
 * purchase tickets and a random winner is selected once the maximum number of 
 * players is reached. The contract also includes functionalities for managing
 * multiple rounds, pausing the lottery, and more.
 */
contract Lottery {
    // State variables
    address public manager; // Address of the manager
    address[] public players; // List of players in the current lottery
    uint public ticketPrice; // Price of a lottery ticket
    uint public maxPlayers; // Maximum number of players allowed in the lottery
    bool public paused; // Boolean to check if the lottery is paused

    // Structure to store details of each lottery round
    struct LotteryRound {
        uint roundNumber; // Lottery round number
        address[] players; // List of players in the round
        address winner; // Winner of the round
        uint prize; // Prize amount for the round
    }

    LotteryRound[] public lotteryRounds; // Array to store all lottery rounds
    uint public currentRound; // Current round number

    // Events
    event LotteryEnter(address indexed player);
    event LotteryWinner(address indexed winner, uint amount);
    event LotteryPaused(bool isPaused);
    event NewLotteryRound(uint roundNumber, uint ticketPrice, uint maxPlayers);

    // Constructor to initialize the manager, ticket price, and maximum players
    constructor(uint _ticketPrice, uint _maxPlayers) {
        manager = msg.sender;
        ticketPrice = _ticketPrice;
        maxPlayers = _maxPlayers;
        paused = false;
        currentRound = 1;
    }

    /**
     * @dev Function to enter the lottery. Players need to send the exact ticket price.
     */
    function enter() public payable {
        require(!paused, "Lottery is paused");
        require(msg.value == ticketPrice, "Incorrect ticket price");
        require(players.length < maxPlayers, "Lottery is full");

        players.push(msg.sender);

        emit LotteryEnter(msg.sender);

        // Check if we have reached the maximum number of players
        if (players.length == maxPlayers) {
            pickWinner();
        }
    }

    /**
     * @dev Function to pick a winner once the maximum number of players is reached.
     * This function is private and can only be called within the contract.
     */
    function pickWinner() private {
        require(players.length == maxPlayers, "Not enough players");

        // Select a random winner
        uint index = random() % players.length;
        address winner = players[index];

        // Transfer the balance to the winner
        uint balance = address(this).balance;
        payable(winner).transfer(balance);

        // Record the lottery round details
        LotteryRound memory round = LotteryRound({
            roundNumber: currentRound,
            players: players,
            winner: winner,
            prize: balance
        });
        lotteryRounds.push(round);

        emit LotteryWinner(winner, balance);

        // Start a new round
        startNewRound();
    }

    /**
     * @dev Function to generate a pseudo-random number.
     * This is not truly random and should not be used for secure randomness.
     */
    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }

    /**
     * @dev Function to get the current players in the lottery.
     * @return An array of addresses of the current players.
     */
    function getPlayers() public view returns (address[] memory) {
        return players;
    }

    /**
     * @dev Modifier to restrict access to the manager.
     */
    modifier restricted() {
        require(msg.sender == manager, "Only the manager can call this function");
        _;
    }

    /**
     * @dev Function to start a new lottery round. This can only be called by the manager.
     * Resets the players array and increments the round number.
     */
    function startNewRound() private restricted {
        require(players.length == maxPlayers, "Current lottery is still ongoing");

        players = new address ; // Reset the players array
        currentRound++;

        emit NewLotteryRound(currentRound, ticketPrice, maxPlayers);
    }

    /**
     * @dev Function to pause or unpause the lottery. This can only be called by the manager.
     * @param _paused A boolean indicating whether to pause or unpause the lottery.
     */
    function setPause(bool _paused) public restricted {
        paused = _paused;

        emit LotteryPaused(_paused);
    }

    /**
     * @dev Function to start a new lottery with specified ticket price and maximum players.
     * This can only be called by the manager.
     * @param _ticketPrice The price of a lottery ticket for the new round.
     * @param _maxPlayers The maximum number of players allowed in the new round.
     */
    function startNewLottery(uint _ticketPrice, uint _maxPlayers) public restricted {
        require(players.length == 0, "Current lottery is still ongoing");

        ticketPrice = _ticketPrice;
        maxPlayers = _maxPlayers;

        emit NewLotteryRound(currentRound, ticketPrice, maxPlayers);
    }
}
