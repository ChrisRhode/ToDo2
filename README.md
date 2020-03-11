# ToDo2
ToDo App in Objective C

This is a "ToDo" list app that does things in ways that I find more useful/helpful than every ToDo list app I've tried so far

1. ToDo list items can have Dates, and there is a view to display items sorted by Date, so that it combines a ToDo list
   and Calendar in one app
2. ToDo list items are hierarchical.  I use the common TableView to implement this.  There is no limit on sublevels.
3. Search and Add are combined in one step.  Too often in other apps I added the same to do list item twice.  As you
   type in an item it incrementally displays any existing items containing that string.  If the item exists you can
   access it directly from the search results by tapping it.  If it doesn't, ending the search with "return" adds it
4. Items can have a "BumpToTop" date and a "DateOfEvent".  E.g. "Income taxes" might have a BumpToTop date of 3/1/2020
   but a DateOfEvent of 04/15/2020.  Items with BumpToTop dates <= the current date will be moved to the top of the list
5. any item can be "bumped" to a higher priority (position) in the list
6. a transaction log is kept showing what was changed, so if you make a weird gesture and don't know if or how it affected
   your to do list, you can find out
   
The Item data is stored in a SQLITE database directly (not using CoreData)
