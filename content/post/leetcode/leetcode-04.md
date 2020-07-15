---
title: "leetcode-04寻找两个正序数组的中位数"
date: 2020-07-14T11:00:00+08:00

tags: ["leetcode","第k大的数"]
categories: ["leetcode"]
---

## 题目
给定两个大小为 m 和 n 的正序（从小到大）数组 nums1 和 nums2。找出这两个正序数组的中位数，并且要求算法的时间复杂度为 `O(log(m + n))`。

https://leetcode-cn.com/problems/median-of-two-sorted-arrays/

## 问题分析
这道题有两道思路:
1. 合并数组用`O(log(m+n))`的方式进行排序,从下标`(((m + n)/2 - 1) + ((m + n)/2)/2) || (m+n)/2`和或则取得最后的数
2. 使用第k大的数 + 二分查找的思想
    1. 算出k是第几大的数,如果为偶数则` k = (m + n + 1)/2` 和 `k = (m + n + 2)/2` 和,奇数中位数一定是 `k = (m + n + 1)/2`
    2. 算出当前需要比较数的个数:`compareNumLength= k/2`, 两个数组比较 `num[compareNumLength - 1]` 处的值,较小的一方的值直接全部舍弃 (特殊情况:`compareNumLength` > 任意一个数组的剩余最大长度 ,将把数组的最大长度作为`compareNumLength`)
    3. 在剩余数组中还需要计算第 `k - compareNumLength`大的值,直到k=1,可以直接算出最大的值
    
## 代码实现

tips:执行用时： 2 ms , 在所有 Java 提交中击败了 100.00% 的用户 内存消耗： 40.7 MB , 在所有 Java 提交中击败了 100.00% 的用户

```java
class Solution {
    public static double findMedianSortedArrays(int[] nums1, int[] nums2) {
        int length1 = nums1.length;
        int length2 = nums2.length;
        int kleft = (nums1.length + nums2.length + 1)/2;
        int kright = (nums1.length + nums2.length + 2)/2;
        return (findMedianSortedArrays(nums1,0,length1 - 1,nums2,0,length2 - 1,kleft) + findMedianSortedArrays(nums1,0,length1 - 1,nums2,0,length2 - 1,kright))/2;
    }

    /**
     * 尾递归比较安全
     * @param nums1
     * @param start1 nums1实际数组开始下标
     * @param end1 nums1实际数组结束下标
     * @param nums2
     * @param start2 nums2实际数组开始下标
     * @param end2 nums2实际数组结束下标
     * @param k 找到第k大的数
     * @return
     */
    private static double findMedianSortedArrays(int[] nums1, int start1, int end1, int[] nums2, int start2, int end2, int k){
        int compareNumLength = k / 2;
        int retainNums1 = end1 - start1 + 1;
        int retainNums2 = end2 - start2 + 1;
        //特殊1中的特殊情况:某个数组为空
        if(retainNums1 == 0){
            return nums2[start2 + k - 1];
        }
        if (retainNums2 == 0){
            return nums1[start1 + k - 1];
        }

        //特殊情况1:compareNumLength下标大于retainNums
        if(compareNumLength > retainNums1){
            compareNumLength = retainNums1;
        }
        if(compareNumLength > retainNums2){
            compareNumLength = retainNums2;
        }

        //特殊情况2:k = 1
        if(k == 1) {
            if(nums1[start1] > nums2[start2]){
                return nums2[start2];
            } else {
                return nums1[start1];
            }
        }

        //以下是比较逻辑
        if(nums1[start1 + compareNumLength - 1] >= nums2[start2 + compareNumLength - 1]){
            return findMedianSortedArrays(nums1, start1, end1, nums2 , start2 + compareNumLength, end2, k - compareNumLength);
        } else {
            return findMedianSortedArrays(nums1, start1 + compareNumLength, end1, nums2 , start2 , end2, k - compareNumLength);
        }
    }
}
```