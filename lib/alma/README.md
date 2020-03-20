## Alma::Electronic

A wrapper for the Alma::Electronic API.

The main entry point is the get methods.

### To get a list of all the collections.

```
Alma::Electronic.get()
```

Will also accept these params:

| Parameter | Type      | Required  | Description |
| --------- | ----------| --------- | ---------------------------------------------------------------------------------------------------------------|
| q         | xs:string | Optional. | Search query. Optional. Searching for words in interface_name, keywords, name or po_line_id (see Brief Search) |
| limit     | xs:int    | Optional. | Default: 10Limits the number of results. Optional. Valid values are 0-100. Default value: 10. |
| offset    | xs:int    | Optional. | Default: 0Offset of the results returned. Optional. Default value: 0, which methodseans that the first results will be returned. |

