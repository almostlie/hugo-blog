---
title: "leetcode-05最长回文子串"
date: 2020-07-15T11:00:00+08:00

tags: ["leetcode","动态规划","中心扩散"]
categories: ["leetcode"]
---

## 题目
给定一个字符串 s，找到 s 中最长的回文子串。你可以假设 s 的最大长度为 1000。

https://leetcode-cn.com/problems/longest-palindromic-substring/

## 问题分析
这道题有三种思路:
- 暴力解法(`o(n^3`))
    1. 循环左下标
    2. 循环右下标
    3. 循环字符串判断是否回文串
- 中心扩散法(`o(n^2)`)
    1. 枚举回文子串的中心位置(中心可能是一个字符,也有可能是两个字符)
    2. 记录最长回文字串
- 动态规划(`o(n^2)`) 每一步的计算都尽可能用到之前计算的结果(空间换时间)
    1. 传入字符串是`string`,定义`left`作为左下标,定义`right`作为右下标,定义`boolean[] dp[left][right]`代表下标left到下标right是否是回文字符串 
    2. `right - left < 2` : `right - left = 0` 一定是回文,`right - left = 1 || right - left = 2` 需要判断左右边界的值(`s.charAt(left) == s.charAt(right)`)相等
    3. `right - left > 2` : 回文是否字符串的值取决于其子串的值(`dp[left][right] = dp[left + 1][right - 1]`)和当前左右边界的值(`string.charAt(left) == string.charAt(left)`)相等 
- Manacher 将字符串进行预处理,在预处理的字符串上进行动态规划和中心扩散算法,比较复杂,暂未研究

## 思路比较
- 动态规划: 暴力解法的优化,枚举字串的数量级是`o(1/2 * n^2)`
- 中心扩散法: 枚举字串的数量级是`o(2*n)`
- 中心扩散法判断字符串是否是回文串,这个值设为t,与`o(n)`相关,一般乱序字符串内的t是个很小的值,在字符串乱序的情况下,中心扩散法好于动态规划法

## 代码实现
```java
//这里给出动态规划的实现
class Solution {
    public String longestPalindrome(String s) {
        int length = s.length();
        boolean[][] dp = new boolean[length][length];
        int maxLeftIndex = 0;
        int maxLength = 0;
        for(int right = 0 ; right < length; right ++){
            for(int left = 0; left <= right ; left ++){
                 //只要左右相当,预先设为true,反之为false
                 dp[left][right] = s.charAt(left) == s.charAt(right);
                 //担有字串且字串不是回文字符串的时候为false
                 if(right - left >= 3 && !dp[left + 1][right - 1]){
                    dp[left][right] = false;
                 }
                 //判断是否最长
                 if(dp[left][right] && maxLength != Math.max(maxLength,right - left + 1)){
                     maxLength = Math.max(maxLength,right - left + 1);
                     maxLeftIndex = left;
                 }
            }
        }
        return s.substring(maxLeftIndex, maxLeftIndex+maxLength);
    }
}
```