sysuse auto, clear
hashsort price
hashsort +price
hashsort rep78 -price
hashsort make
hashsort foreign -make

* One thing that is useful is that hashsort can encode a set of variables and
* set the encoded variable as the sorting variable:

sysuse auto, clear

hashsort foreign -make, group(id) sortgroup

id
