QueueOp
===========

Single Reader Multiple writer Queue Implementation for reading and writing datasets.


Enqueue(Dataset, QueueName) - Writes the dataset as a new Item to the bottom of the queue. There is no create queue. The first enqueue will automatically create the queue. 

Peek(QueueName) - Peek into the item at the top of the queue without removing the item from the queue

Dequeue(QueueName,LocationPrefix) - Will dequeue the top item from the queue and place it in the locationprefix specified. It will return the file name of the dequeued item.

DequeueAll(QueueName,LocationPrefix) - Will merge all the items in the queue at that point in time and place it as a single file in the locationprefix specified. It will return the file name of the merged dequeued items.

QueueLength(QueueName) - Will give the number of items in the queue. 

ClearQueue(QueueName,Force) - Will clear the queue deleting the items it contains. Will fail if the queue is locked for a dequeue. Force will override and clear the queue anyways (may destabilize other jobs and should be used only after understanding the implications).   

*** Since this is a single reader queue only one instance of either Dequeue, DequeueAll, ClearQueue can access the queue at any point in time. 

*** Simultaneous access to dequeue or clear will fail one of the process. 

*** You can use the RECOVERY work flow service to implement re-try attempts based on your requirements.


