---
title: "leetcode-06 Z 字形变换"
date: 2020-07-16T15:00:00+08:00

tags: ["leetcode"]
categories: ["leetcode"]
---

## 题目
将一个给定字符串根据给定的行数，以从上往下、从左到右进行 Z 字形排列。

https://leetcode-cn.com/problems/zigzag-conversion/solution/z-zi-xing-bian-huan-by-leetcode/

## 问题分析
这道题有两种思路
1. 按行建立数组,推断下一个数的行号,填入对应数组中
    - 优点:简单,速度快:时间复杂度o(n)系数为1
    - 确定:空间复杂度o(n)系数为2
2. 找规律(比较麻烦)
    - 优点:空间复杂度o(n)系数为1
    - 缺点:时间复杂度o(n)系数为numRows

## 代码实现
```java
//找规律 推断下一个数的行号
class Solution {
    public static String convert(String s, int numRows) {
        //一行直接毙掉
        if(numRows < 2){
            return s;
        }
        //确定一共要有几行
        int row = Math.min(s.length(),numRows);
        List<StringBuilder> stringBuilderList = new ArrayList<>();
        for(int i = 0 ; i < row ;i ++){
            stringBuilderList.add(new StringBuilder());
        }
        int index = 0, flag = 1;
        for(char c : s.toCharArray()){
            stringBuilderList.get(index).append(c);
            index += flag;
            if(index == 2 || index == 0){
                flag = -flag;
            }
        }
        StringBuilder result = new StringBuilder();
        for(StringBuilder stringBuilder  : stringBuilderList){
            result.append(stringBuilder);
        }
        return result.toString();
    }
}

//找规律
class Solution {
    public static String convert(String s, int numRows) {
        if(s.length() == 0 || numRows == 1){
            return s;
        }
        StringBuilder result = new StringBuilder();
        int barriar = 2 * numRows - 2;
        int fullCycle = s.length() / barriar;
        int remain = s.length() % barriar;
        for(int i = 0 ; i < fullCycle; i++){
            result.append(s.charAt(i * barriar));
        }
        if(remain > 0){
            result.append(s.charAt(fullCycle * barriar));
        }

        for(int k = 0 ;k < numRows - 2 ;k ++){
            for(int i = 0 ; i < fullCycle; i++){
                result.append(s.charAt(i * barriar + k + 1)).append(s.charAt(i * barriar + barriar - k - 1));
            }

            if(remain >= k + 2){
                result.append(s.charAt(fullCycle * barriar + k + 1));
            }
            if(remain > barriar - k - 1){
                result.append(s.charAt(fullCycle * barriar + barriar - k - 1));
            }
        }

        for(int i = 0 ; i < fullCycle; i++){
            result.append(s.charAt(i * barriar + numRows - 1));
        }
        if(remain >= numRows){
            result.append(s.charAt(fullCycle * barriar + numRows - 1));
        }
        return result.toString();
    }
}
```