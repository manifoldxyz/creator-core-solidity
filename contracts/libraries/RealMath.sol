// File: contracts\libs\RealMath.sol

pragma solidity ^0.8.0;

/**
 * Reference: https://github.com/balancer-labs/balancer-core/blob/master/contracts/BNum.sol
 */

library RealMath {

    uint256 private constant BONE           = 10 ** 18;
    uint256 private constant MIN_BPOW_BASE  = 1 wei;
    uint256 private constant MAX_BPOW_BASE  = (2 * BONE) - 1 wei;
    uint256 private constant BPOW_PRECISION = BONE / 10 ** 10;
    uint256 public constant BPOW_PRECISION2 = BONE / 10 ** 10;

    /**
     * @dev 
     */
    function rtoi(uint256 a)
        internal
        pure 
        returns (uint256)
    {
        return a / BONE;
    }

    /**
     * @dev 
     */
    function rfloor(uint256 a)
        internal
        pure
        returns (uint256)
    {
        return rtoi(a) * BONE;
    }

    /**
     * @dev 
     */
    function radd(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        uint256 c = a + b;

        require(c >= a, "ERR_ADD_OVERFLOW");
        
        return c;
    }

    /**
     * @dev 
     */
    function rsub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        (uint256 c, bool flag) = rsubSign(a, b);

        require(!flag, "ERR_SUB_UNDERFLOW");

        return c;
    }

    /**
     * @dev 
     */
    function rsubSign(uint256 a, uint256 b)
        internal
        pure
        returns (uint256, bool)
    {
        if (a >= b) {
            return (a - b, false);

        } else {
            return (b - a, true);
        }
    }

    /**
     * @dev 
     */
    function rmul(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        uint256 c0 = a * b;

        require(a == 0 || c0 / a == b, "ERR_MUL_OVERFLOW");

        uint256 c1 = c0 + (BONE / 2);

        require(c1 >= c0, "ERR_MUL_OVERFLOW");

        return c1 / BONE;
    }

    /**
     * @dev 
     */
    function rdiv(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        require(b != 0, "ERR_DIV_ZERO");

        uint256 c0 = a * BONE;

        require(a == 0 || c0 / a == BONE, "ERR_DIV_INTERNAL");

        uint256 c1 = c0 + (b / 2);

        require(c1 >= c0, "ERR_DIV_INTERNAL");

        return c1 / b;
    }

    /**
     * @dev 
     */
    function rpowi(uint256 a, uint256 n)
        internal
        pure
        returns (uint256)
    {
        uint256 z = n % 2 != 0 ? a : BONE;

        for (n /= 2; n != 0; n /= 2) {
            a = rmul(a, a);

            if (n % 2 != 0) {
                z = rmul(z, a);
            }
        }

        return z;
    }

    /**
     * @dev Computes b^(e.w) by splitting it into (b^e)*(b^0.w).
     * Use `rpowi` for `b^e` and `rpowK` for k iterations of approximation of b^0.w
     */
    function rpow(uint256 base, uint256 exp)
        internal
        pure
        returns (uint256)
    {
        require(base >= MIN_BPOW_BASE, "ERR_BPOW_BASE_TOO_LOW");
        require(base <= MAX_BPOW_BASE, "ERR_BPOW_BASE_TOO_HIGH");

        uint256 whole = rfloor(exp);   
        uint256 remain = rsub(exp, whole);

        uint256 wholePow = rpowi(base, rtoi(whole));

        if (remain == 0) {
            return wholePow;
        }

        uint256 partialResult = rpowApprox(base, remain, BPOW_PRECISION);

        return rmul(wholePow, partialResult);
    }

    /**
     * @dev 
     */
    function rpowApprox(uint256 base, uint256 exp, uint256 precision)
        internal
        pure
        returns (uint256)
    {
        (uint256 x, bool xneg) = rsubSign(base, BONE);

        uint256 a = exp;
        uint256 term = BONE;
        uint256 sum = term;

        bool negative = false;

        // term(k) = numer / denom 
        //         = (product(a - i - 1, i = 1--> k) * x ^ k) / (k!)
        // Each iteration, multiply previous term by (a - (k - 1)) * x / k
        // continue until term is less than precision
        for (uint256 i = 1; term >= precision; i++) {
            uint256 bigK = i * BONE;

            (uint256 c, bool cneg) = rsubSign(a, rsub(bigK, BONE));

            term = rmul(term, rmul(c, x));
            term = rdiv(term, bigK);

            if (term == 0) break;

            if (xneg) negative = !negative;
            if (cneg) negative = !negative;

            if (negative) {
                sum = rsub(sum, term);

            } else {
                sum = radd(sum, term);
            }
        }

        return sum;
    }

}