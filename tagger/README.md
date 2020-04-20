### What is tagger-script?

 - This is a script for tagging all the repositories.
   Before each production release, we need to tag each repositories with release tag.


### What modifications are required before each release?

- In this script we need to change the release tag version. e.g.
```
version = "x.y.z"
```

- In this script we need to modify the list of all repo names and the commit id against which we want to tag the version name. e.g.
```
repos = %{repo-name-1 commit-hash-1
  repo-name-2 commit-hash-2
  repo-name-3 commit-hash-3
  repo-name-4 commit-hash-4
}
```
### How to run the Script?

```
$ ./tagger-script > tag-repo.sh
$ chmod +x tag-repo.sh
$ ./tag-repo.sh
```
