// SPDX-License-Identifier: MIT

pragma solidity 0.6.4;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "./libraries/SafeERC20.sol";
import "./libraries/Math.sol";

contract KunWrapper {
    using SafeMath for uint256;

    using SafeERC20 for IERC20;

    /// @notice 总锁仓量
    uint256 private _totalSupply;

    /// @notice 用户锁仓量
    mapping(address => uint256) private _balances;

    /// @notice kun 代币的地址
    address public kun;

    /// @notice 总锁仓量
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /// @notice 用户锁仓量
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /// @notice 质押
    function stake(uint256 amount) public virtual {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        IERC20(kun).safeTransferFrom(msg.sender, address(this), amount);
    }

    /// @notice 退出质押
    function withdraw(uint256 amount) public virtual {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        IERC20(kun).safeTransfer(msg.sender, amount);
    }
}

contract KunStakePool is KunWrapper, Initializable {
    using SafeERC20 for IERC20;

    using SafeMath for uint256;

    /// @notice 管理员
    address public owner;

    /// @notice 活动开始时间
    uint256 public startTime;

    /// @notice 活动结束事件
    uint256 public periodFinish;

    /// @notice 上次更新时间
    uint256 public lastUpdateTime;

    /// @notice 每单位的 token 获得的奖励值
    uint256 public rewardPerTokenStored;

    /// @notice 双周事件
    uint256 public constant DW_TIME = 14 days;

    /// @notice 持续时间 （96 个双周）
    uint256 public constant DURATION = 672 days;

    /// @notice 用户每单位的 token 已获得的奖励值
    mapping(address => uint256) public userRewardPerTokenPaid;

    /// @notice 用户获得的奖励
    mapping(address => uint256) public rewards;

    /// @notice 双周信息
    /// @param startTime 开始时间
    /// @param totalStake 总质押量
    /// @param stakeTarget 质押目标
    /// @param totalReward 总奖励
    /// @param rewardRate 奖励分发速率
    struct DWInfo {
        uint256 startTime;
        uint256 totalStake;
        uint256 stakeTarget;
        uint256 totalReward;
        uint256 rewardRate;
    }

    /// @notice 双周数 => 双周信息
    mapping(uint256 => DWInfo) public dwInfo;

    /// @dev 防止重入
    bool internal _notEntered;

    /// @notice 事件：管理员取回合约中的所有余额
    /// @param kun kun 代币地址
    /// @param balance 余额
    event ClaimTokens(address kun, uint256 balance);

    /// @notice 事件：用户质押
    /// @param user 用户地址
    /// @param amount 质押数量
    event Staked(address indexed user, uint256 amount);

    /// @notice 事件：用户取回一定数量的质押
    /// @param user 用户地址
    /// @param amount 质押数量
    event Withdrawn(address indexed user, uint256 amount);

    /// @notice 事件：奖励分发
    /// @param user 用户地址
    /// @param reward 奖励分发数量
    event RewardPaid(address indexed user, uint256 reward);

    /// @notice 初始化函数
    /// @param _owner 管理员地址
    /// @param _kun kun 代币地址
    /// @param _startTime 活动开始时间
    function initialize(
        address _owner,
        address _kun,
        uint256 _startTime
    ) public initializer {
        owner = _owner;
        kun = _kun;
        startTime = _startTime;
        periodFinish = startTime.add(DURATION);
        _notEntered = true;
    }

    modifier checkStart() {
        require(block.timestamp > startTime, "not start");
        _;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        // 更新本周 stake 数量
        uint256 currentDWNumber = getDoubleWeekNumber(lastUpdateTime);
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    modifier nonReentrant() {
        require(_notEntered, "re-entered");
        _notEntered = false;
        _;
        _notEntered = true;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    /// @notice 获取时间
    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    /// @notice 计算每个 token 可以获得奖励数量（涉及到更新数据）
    function rewardPerToken() internal returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        uint256 res = rewardPerTokenStored;
        uint256 currentDWNumber = getDoubleWeekNumber(
            lastTimeRewardApplicable()
        );
        if (currentDWNumber == 1) {
            // 第一个双周
            res = res.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(dwInfo[1].rewardRate)
                    .mul(1e18)
                    .div(totalSupply()) //
            );
        } else {
            // 获取上次操作的双周数
            uint256 lastOpDWNumber = getDoubleWeekNumber(lastUpdateTime);
            if (lastOpDWNumber < currentDWNumber) {
                // 如果上次操作时间与本次操作时间不在同一 +双周+ 内，那么会有两种情况
                // 1、上次操作的 +双周+ 与 本次操作的 +双周+ 相连
                // 即上次操作是在第 n 个双周，本次是在第 n + 1 个双周

                // 这里是更新第 n 的双周时，操作时间与 n 的结束时间的 rewardPerToken
                res = res.add(
                    dwInfo[lastOpDWNumber + 1]
                        .startTime
                        .sub(lastUpdateTime)
                        .mul(dwInfo[lastOpDWNumber].rewardRate)
                        .mul(1e18)
                        .div(totalSupply())
                );
                dwInfo[lastOpDWNumber].totalStake = totalSupply();
                // 2、上次操作的 +双周+ 与 本次操作的 +双周+ 中间相隔 m 个 +双周+
                // 即上次操作是在第 n 个双周，本次是在第 n + m 个双周（m > 1）

                // 这里是更新第 n 的双周后，m 个双周的 rewardPerToken
                for (uint256 i = lastOpDWNumber + 1; i < currentDWNumber; ++i) {
                    DWInfo memory lastOpDWInfo = dwInfo[i - 1];
                    // DWInfo memory lastDWInfo = dwInfo[i];

                    uint256 lastRewardRate = (
                        lastOpDWInfo.totalStake >= lastOpDWInfo.stakeTarget
                            ? lastOpDWInfo.totalReward
                            : lastOpDWInfo
                                .totalStake
                                .mul(dwInfo[i].totalReward)
                                .div(lastOpDWInfo.stakeTarget)
                    ) / DW_TIME;

                    dwInfo[i].rewardRate = lastRewardRate;
                    dwInfo[i].totalStake = totalSupply();

                    res = res.add(
                        DW_TIME.mul(dwInfo[i].rewardRate).mul(1e18).div(
                            totalSupply()
                        )
                    );
                }
                lastUpdateTime = dwInfo[currentDWNumber].startTime;
                // 这里是根据上个 +双周+ 的数据计算本次 +双周+ 的 rewardRate
                DWInfo memory prevDWInfo = dwInfo[currentDWNumber - 1];
                uint256 currentRewardRate = (
                    prevDWInfo.totalStake >= prevDWInfo.stakeTarget
                        ? prevDWInfo.totalReward
                        : prevDWInfo
                            .totalStake
                            .mul(dwInfo[currentDWNumber].totalReward)
                            .div(prevDWInfo.stakeTarget)
                ) / DW_TIME;
                dwInfo[currentDWNumber].rewardRate = currentRewardRate;
            }
            // 更新本个双周内，上次更新时间到本次时间的 rewardPerToken
            res = res.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(dwInfo[currentDWNumber].rewardRate)
                    .mul(1e18)
                    .div(totalSupply())
            );
        }
        return res;
    }

    /// @notice 计算每个 token 可以获得奖励数量（不更新数据，用于显示）
    function readRewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        uint256 res = rewardPerTokenStored;
        uint256 currentDWNumber = getDoubleWeekNumber(
            lastTimeRewardApplicable()
        );

        DWInfo[] memory infos = new DWInfo[](currentDWNumber + 1);
        uint256 tmpLastUpdateTime = lastUpdateTime;

        if (currentDWNumber == 1) {
            // 第一个双周
            res = res.add(
                lastTimeRewardApplicable()
                    .sub(tmpLastUpdateTime)
                    .mul(dwInfo[1].rewardRate)
                    .mul(1e18)
                    .div(totalSupply()) //
            );
        } else {
            for (uint256 i = 1; i <= currentDWNumber; ++i) {
                infos[i] = dwInfo[i];
            }

            // 获取上次操作的双周数
            uint256 lastOpDWNumber = getDoubleWeekNumber(tmpLastUpdateTime);
            if (lastOpDWNumber < currentDWNumber) {
                // 如果上次操作时间与本次操作时间不在同一 +双周+ 内，那么会有两种情况
                // 1、上次操作的 +双周+ 与 本次操作的 +双周+ 相连
                // 即上次操作是在第 n 个双周，本次是在第 n + 1 个双周

                // 这里是更新第 n 的双周时，操作时间与 n 的结束时间的 rewardPerToken
                res = res.add(
                    infos[lastOpDWNumber + 1]
                        .startTime
                        .sub(tmpLastUpdateTime)
                        .mul(infos[lastOpDWNumber].rewardRate)
                        .mul(1e18)
                        .div(totalSupply())
                );
                infos[lastOpDWNumber].totalStake = totalSupply();
                // 2、上次操作的 +双周+ 与 本次操作的 +双周+ 中间相隔 m 个 +双周+
                // 即上次操作是在第 n 个双周，本次是在第 n + m 个双周（m > 1）

                // 这里是更新第 n 的双周后，m 个双周的 rewardPerToken
                for (uint256 i = lastOpDWNumber + 1; i < currentDWNumber; ++i) {
                    DWInfo memory lastOpDWInfo = infos[i - 1];
                    // DWInfo memory lastDWInfo = infos[i];

                    uint256 lastRewardRate = (
                        lastOpDWInfo.totalStake >= lastOpDWInfo.stakeTarget
                            ? lastOpDWInfo.totalReward
                            : lastOpDWInfo
                                .totalStake
                                .mul(infos[i].totalReward)
                                .div(lastOpDWInfo.stakeTarget)
                    ) / DW_TIME;

                    infos[i].rewardRate = lastRewardRate;
                    infos[lastOpDWNumber].totalStake = totalSupply();

                    res = res.add(
                        DW_TIME.mul(infos[i].rewardRate).mul(1e18).div(
                            totalSupply()
                        )
                    );
                }
                tmpLastUpdateTime = infos[currentDWNumber].startTime;
                // 这里是根据上个 +双周+ 的数据计算本次 +双周+ 的 rewardRate
                DWInfo memory prevDWInfo = infos[currentDWNumber - 1];
                uint256 currentRewardRate = (
                    prevDWInfo.totalStake >= prevDWInfo.stakeTarget
                        ? prevDWInfo.totalReward
                        : prevDWInfo
                            .totalStake
                            .mul(dwInfo[currentDWNumber].totalReward)
                            .div(prevDWInfo.stakeTarget)
                ) / DW_TIME;
                infos[currentDWNumber].rewardRate = currentRewardRate;
            }
            // 更新本个双周内，上次更新时间到本次时间的 rewardPerToken
            res = res.add(
                lastTimeRewardApplicable()
                    .sub(tmpLastUpdateTime)
                    .mul(infos[currentDWNumber].rewardRate)
                    .mul(1e18)
                    .div(totalSupply())
            );
        }
        return res;
    }

    /// @notice 计算用户可以获得的奖励数量
    function earned(address account) internal returns (uint256) {
        return
            balanceOf(account)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    /// @notice 计算用户可以获得的奖励数量（用于页面显示）
    function readEarned(address account) public view returns (uint256) {
        return
            balanceOf(account)
                .mul(readRewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    /// @notice 计算用户可以获得的奖励数量（用于页面显示）
    /// @param _startTime 设置开始时间
    function setStartTime(uint256 _startTime) external onlyOwner {
        startTime = _startTime;
    }

    /// @notice 用户质押
    /// @param amount 质押数量
    function stake(uint256 amount)
        public
        override
        updateReward(msg.sender)
        checkStart
        nonReentrant
    {
        require(amount > 0, "Cannot stake 0");
        super.stake(amount);
        emit Staked(msg.sender, amount);
    }

    /// @notice 用户取回一定数量的质押代币
    /// @param amount 取回数量
    function withdraw(uint256 amount)
        public
        override
        updateReward(msg.sender)
        checkStart
        nonReentrant
    {
        require(amount > 0, "Cannot withdraw 0");
        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
    }

    /// @notice 用户退出活动，取出所有质押代币与奖励
    function exit() external checkStart nonReentrant {
        withdraw(balanceOf(msg.sender));
        getReward();
    }

    /// @notice 用户获取奖励代币
    function getReward()
        public
        updateReward(msg.sender)
        checkStart
        nonReentrant
    {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            IERC20(kun).safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    /// @notice 根据时间戳获取双周数
    /// @param timestamp 时间戳
    function getDoubleWeekNumber(uint256 timestamp)
        public
        view
        returns (uint256)
    {
        return (timestamp - startTime) / DW_TIME + 1;
    }

    /// @notice 设置活动信息
    /// @param dw 每个双周的序号
    /// @param _startTime 每个双周的开始时间
    /// @param _stakeTarget 每个双周的质押目标
    /// @param _totalReward 每个双周的奖励总数
    function setDWInfo(
        uint256[] calldata dw,
        uint256[] calldata _startTime,
        uint256[] calldata _stakeTarget,
        uint256[] calldata _totalReward
    ) external onlyOwner {
        uint256 length = dw.length;
        require(
            length == _startTime.length &&
                length == _stakeTarget.length &&
                length == _totalReward.length,
            "Invalid input"
        );
        for (uint256 i = 0; i < length; ++i) {
            dwInfo[dw[i]].startTime = _startTime[i];
            dwInfo[dw[i]].stakeTarget = _stakeTarget[i];
            dwInfo[dw[i]].totalReward = _totalReward[i];
        }
    }

    /// @notice 设置第一周的分发速率
    function setFirstDWRewardRate() external onlyOwner {
        dwInfo[1].rewardRate = dwInfo[1].totalReward / DW_TIME;
    }

    /// @notice 设置 kun 代币地址
    /// @param _kun kun 代币地址
    function setKun(address _kun) external onlyOwner {
        kun = _kun;
    }

    /// @notice 管理员取出所有质押
    function claimTokens() external onlyOwner {
        uint256 balance = IERC20(kun).balanceOf(address(this));
        IERC20(kun).safeTransfer(owner, balance);
        emit ClaimTokens(kun, balance);
    }
}
