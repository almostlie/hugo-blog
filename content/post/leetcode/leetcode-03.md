---
title: "leetcode-03无重复字符的最长子串"
date: 2020-07-13T11:04:00+08:00

tags: ["leetcode","滑动窗口"]
categories: ["leetcode"]
---

## 题目
给定一个字符串，请你找出其中不含有重复字符的 最长子串 的长度。

https://leetcode-cn.com/problems/longest-substring-without-repeating-characters/

## 问题分析
这道题主要用到思路是：滑动窗口

使用一个队列,比如例题中的 abcabcbb，进入这个队列（窗口）为 abc 满足题目要求，当再进入 a，队列变成了 abca，这时候不满足要求。所以，我们要移动这个队列

如何移动?当abc满足题目要求时:
1. 通过hash保存abc的值与下标为`HashMap<value,index>`,`left = 0`为左指针,`right = 0`为右指针,右指针驱动循环
2. 队列变成了 abca,更改left的下标为倒数第二个a的位置的下标,并将左指针向`penultimate_a + 1`
3. 队列变成了 abcac,更改left的下标为倒数第二个c的位置的下标,并将左指针指向`penultimate_c + 1`
4. 队列变成了 abcacb,更改left的下标为倒数第二个b的位置的下标,但是倒数第二个b位置的下标小于当前下标,不做改动

hash的重要性:例如上述第三步,可以直接跳过b,将整体时间复杂度从o(n^2)降低到o(n)

## 代码实现
```java
class Solution {
    public int lengthOfLongestSubstring(String s) {
        Map<Character,Integer> map = new HashMap<>();
        int left = 0;
        int maxLength = 0;
        for(int i = 0; i < s.length(); i++){
            if(map.containsKey(s.charAt(i))){
                //注意,map.get(s.charAt(i))有可能是left左边已经被跳过,如上例子中的字符b,已被记录但未被移除
                left = Math.max(left,map.get(s.charAt(i)) + 1);
            }
            map.put(s.charAt(i),i);
            maxLength = Math.max(maxLength,i - left + 1);
        }
        return maxLength;
    }
}
```