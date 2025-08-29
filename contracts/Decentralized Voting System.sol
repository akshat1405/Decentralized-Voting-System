// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;


/**
 * @title DecentralizedVotingSystem
 * @dev A transparent and secure voting system for proposals and elections
 * @author Your Name
 */
contract DecentralizedVotingSystem {
    // Structs
    struct Proposal {
        uint256 id;
        string title;
        string description;
        address proposer;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 totalVotes;
        uint256 startTime;
        uint256 endTime;
        bool executed;
        bool exists;
    }
    
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint256 votedProposalId;
        uint256 registrationTime;
    }
    
    // State variables
    address public admin;
    uint256 public proposalCount;
    uint256 public voterCount;
    uint256 public constant VOTING_DURATION = 7 days;
    uint256 public constant REGISTRATION_PERIOD = 1 days;
    
    // Mappings
    mapping(uint256 => Proposal) public proposals;
    mapping(address => Voter) public voters;
    mapping(uint256 => mapping(address => bool)) public hasVotedOnProposal;
    
    // Events
    event VoterRegistered(address indexed voter, uint256 timestamp);
    event ProposalCreated(
        uint256 indexed proposalId,
        string title,
        address indexed proposer,
        uint256 startTime,
        uint256 endTime
    );
    event VoteCast(
        address indexed voter,
        uint256 indexed proposalId,
        bool vote,
        uint256 timestamp
    );
    event ProposalExecuted(uint256 indexed proposalId, bool result);
    
    // Modifiers
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }
    
    modifier onlyRegisteredVoter() {
        require(voters[msg.sender].isRegistered, "Voter not registered");
        _;
    }
    
    modifier proposalExists(uint256 _proposalId) {
        require(proposals[_proposalId].exists, "Proposal does not exist");
        _;
    }
    
    modifier votingActive(uint256 _proposalId) {
        require(
            block.timestamp >= proposals[_proposalId].startTime &&
            block.timestamp <= proposals[_proposalId].endTime,
            "Voting period is not active"
        );
        _;
    }
    
    constructor() {
        admin = msg.sender;
        proposalCount = 0;
        voterCount = 0;
    }
    
    /**
     * @dev Register a new voter in the system
     * @param _voter Address of the voter to register
     */
    function registerVoter(address _voter) external onlyAdmin {
        require(_voter != address(0), "Invalid voter address");
        require(!voters[_voter].isRegistered, "Voter already registered");
        
        voters[_voter] = Voter({
            isRegistered: true,
            hasVoted: false,
            votedProposalId: 0,
            registrationTime: block.timestamp
        });
        
        voterCount++;
        emit VoterRegistered(_voter, block.timestamp);
    }
    
    /**
     * @dev Create a new proposal for voting
     * @param _title Title of the proposal
     * @param _description Detailed description of the proposal
     */
    function createProposal(
        string memory _title,
        string memory _description
    ) external onlyRegisteredVoter {
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(bytes(_description).length > 0, "Description cannot be empty");
        
        proposalCount++;
        uint256 startTime = block.timestamp + REGISTRATION_PERIOD;
        uint256 endTime = startTime + VOTING_DURATION;
        
        proposals[proposalCount] = Proposal({
            id: proposalCount,
            title: _title,
            description: _description,
            proposer: msg.sender,
            yesVotes: 0,
            noVotes: 0,
            totalVotes: 0,
            startTime: startTime,
            endTime: endTime,
            executed: false,
            exists: true
        });
        
        emit ProposalCreated(
            proposalCount,
            _title,
            msg.sender,
            startTime,
            endTime
        );
    }
    
    /**
     * @dev Cast a vote on a specific proposal
     * @param _proposalId ID of the proposal to vote on
     * @param _vote True for YES, False for NO
     */
    function castVote(
        uint256 _proposalId,
        bool _vote
    ) external 
        onlyRegisteredVoter 
        proposalExists(_proposalId) 
        votingActive(_proposalId) 
    {
        require(
            !hasVotedOnProposal[_proposalId][msg.sender],
            "Already voted on this proposal"
        );
        
        // Record the vote
        hasVotedOnProposal[_proposalId][msg.sender] = true;
        
        if (_vote) {
            proposals[_proposalId].yesVotes++;
        } else {
            proposals[_proposalId].noVotes++;
        }
        
        proposals[_proposalId].totalVotes++;
        
        // Update voter's status
        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedProposalId = _proposalId;
        
        emit VoteCast(msg.sender, _proposalId, _vote, block.timestamp);
    }
    
    // View functions
    function getProposal(uint256 _proposalId) 
        external 
        view 
        proposalExists(_proposalId)
        returns (
            uint256 id,
            string memory title,
            string memory description,
            address proposer,
            uint256 yesVotes,
            uint256 noVotes,
            uint256 totalVotes,
            uint256 startTime,
            uint256 endTime,
            bool executed
        ) 
    {
        Proposal memory proposal = proposals[_proposalId];
        return (
            proposal.id,
            proposal.title,
            proposal.description,
            proposal.proposer,
            proposal.yesVotes,
            proposal.noVotes,
            proposal.totalVotes,
            proposal.startTime,
            proposal.endTime,
            proposal.executed
        );
    }
    
    function getVoterInfo(address _voter) 
        external 
        view 
        returns (
            bool isRegistered,
            bool hasVoted,
            uint256 votedProposalId,
            uint256 registrationTime
        ) 
    {
        Voter memory voter = voters[_voter];
        return (
            voter.isRegistered,
            voter.hasVoted,
            voter.votedProposalId,
            voter.registrationTime
        );
    }
    
    function getProposalResult(uint256 _proposalId) 
        external 
        view 
        proposalExists(_proposalId)
        returns (
            bool votingEnded,
            bool passed,
            uint256 yesVotes,
            uint256 noVotes,
            uint256 totalVotes,
            uint256 yesPercentage
        ) 
    {
        Proposal memory proposal = proposals[_proposalId];
        bool ended = block.timestamp > proposal.endTime;
        bool proposalPassed = proposal.yesVotes > proposal.noVotes;
        uint256 yesPercent = proposal.totalVotes > 0 ? 
            (proposal.yesVotes * 100) / proposal.totalVotes : 0;
        
        return (
            ended,
            proposalPassed,
            proposal.yesVotes,
            proposal.noVotes,
            proposal.totalVotes,
            yesPercent
        );
    }
    
    function isVotingActive(uint256 _proposalId) 
        external 
        view 
        proposalExists(_proposalId)
        returns (bool) 
    {
        return (
            block.timestamp >= proposals[_proposalId].startTime &&
            block.timestamp <= proposals[_proposalId].endTime
        );
    }
    
    function getAllProposals() external view returns (uint256[] memory) {
        uint256[] memory proposalIds = new uint256[](proposalCount);
        for (uint256 i = 1; i <= proposalCount; i++) {
            proposalIds[i-1] = i;
        }
        return proposalIds;
    }
    
    function getActiveProposals() external view returns (uint256[] memory) {
        uint256 activeCount = 0;
        
        // Count active proposals
        for (uint256 i = 1; i <= proposalCount; i++) {
            if (block.timestamp >= proposals[i].startTime && 
                block.timestamp <= proposals[i].endTime) {
                activeCount++;
            }
        }
        
        // Create array of active proposal IDs
        uint256[] memory activeProposals = new uint256[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= proposalCount; i++) {
            if (block.timestamp >= proposals[i].startTime && 
                block.timestamp <= proposals[i].endTime) {
                activeProposals[index] = i;
                index++;
            }
        }
        
        return activeProposals;
    }
    
    // Administrative functions
    function executeProposal(uint256 _proposalId) 
        external 
        onlyAdmin 
        proposalExists(_proposalId) 
    {
        require(
            block.timestamp > proposals[_proposalId].endTime,
            "Voting period not ended"
        );
        require(!proposals[_proposalId].executed, "Proposal already executed");
        
        bool result = proposals[_proposalId].yesVotes > proposals[_proposalId].noVotes;
        proposals[_proposalId].executed = true;
        
        emit ProposalExecuted(_proposalId, result);
    }
    
    function emergencyPause() external onlyAdmin {
        // Emergency function to pause contract operations if needed
        // Implementation depends on specific requirements
    }
    
    function transferAdminRole(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "Invalid admin address");
        admin = _newAdmin;
    }
}
