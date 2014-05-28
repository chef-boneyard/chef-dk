Dev Cookbook Fixtures

Cookbooks in here that are used to represent local checkouts of a
git-hosted cookbook are stored as git bundles to avoid problems with git
assuming the cookbooks are submodules. For more information, read the
`git-bundle` manpage (`git help bundle`). The short version is that you
can treat the git bundle as a regular git remote if you need to modify
the fixture data:

```
cd staging_dir
git clone $prefix/cookbook.gitbundle
# make edits, commit
git push
```

