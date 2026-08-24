### [H-03] `Snow::earnSnow` uses a single global timer instead of a per-user timer

**Severity:** High

**Description**

`s_earnTimer` is declared as a single `uint256` instead of tracking a separate timer for each user:

    uint256 private s_earnTimer;

    function earnSnow() external canFarmSnow { 
        if (s_earnTimer != 0 && block.timestamp < (s_earnTimer + 1 weeks)) { 
            revert S__Timer(); 
        } 
        _mint(msg.sender, 1); 
        s_earnTimer = block.timestamp; 
    }

The intended behavior is for each user to be able to earn 1 free Snow token once per week.

However, because there is only one shared timer, the cooldown applies to the entire contract rather than to the individual caller.

For example, if Alice calls `earnSnow()`, `s_earnTimer` is updated to the current timestamp. Bob then cannot call `earnSnow()` during that same week, even though Bob has never used the function before.

**Impact**

A single user's call to `earnSnow()` prevents every other user from earning Snow until one week has passed from that call.

A user can also repeatedly call `earnSnow()` as soon as the cooldown expires, resetting the global timer and potentially preventing other users from ever using the free-earning mechanism.

This breaks the intended per-user weekly earning mechanism and allows one address to interfere with the ability of every other address to earn Snow.

**Proof of Concept**

_Pending — write a test where address A calls `earnSnow()`, then address B calls `earnSnow()` during the same week and verify that B's transaction reverts even though B has never called `earnSnow()` before._

**Recommended Mitigation**

Use a separate timer for each address:

    mapping(address => uint256) private s_earnTimer;

    function earnSnow() external canFarmSnow { 
        if (s_earnTimer[msg.sender] != 0 && block.timestamp < (s_earnTimer[msg.sender] + 1 weeks)) { 
            revert S__Timer(); 
        } 
        _mint(msg.sender, 1); 
        s_earnTimer[msg.sender] = block.timestamp; 
    }