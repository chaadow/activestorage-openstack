# activestorage-openstack changelog

## 1.5.2 (2021-09-17)
- Lazy client initialization prevents application crash at startup when
  openstack service is unavailable. ( @arekk )

## 1.5.1 (2020-12-24)
- Fix `#headers_for_direct_upload` to make `:filename` an optional kwarg

## 1.5.0 (2020-12-22)
- Add support for rails 6.1
 - Add public/private url support ( Co-Authored with @jplot )
 - Add more test coverage for new API/behaviour
- Update `#url_for_direct_upload` to accept `filename:` as allowed by
  `fog-openstack` libray
- Add appraisal to handle multiple rails versions including rails master
- Rubocop fixes
- Update README with rails 6.1 config examples
- Code cleaning

## 1.4.2 (2020-11-11)
- Optimize `#exists?` checks to request the head of the file instead of
  requesting the entire file

## 1.4.1 (2020-03-03)
- Avoid double wrap of filename in `ActiveStorage::Filename`

## 1.3.0 (2020-11-26)
- Rails 6.0.1 now aliases `create_after_upload` to `create_and_upload`
forcing the creation of the blob before uplaoding to the blob provider.
This causes a bug with this plugin since an after_commit hook has been added
when a blob is created that updates the metadata(content type) of the
blob on the openstack provider assuming the blob had already
been uploaded beforehand.
An `ActiveStorage::FileNotFound` error is then raised because it tries
to update the metadata of a file that does not exist yet.

- This hook is now totally removed. However for versions that are inferior
to rails 6.0.1, and starting from `5.2.1.1`, Rails has added native
support for a method called `update_metadata` that calls the service and
tries to update the blob in case it has not been identified yet.
To make this plugin work for all versions, the `update_metadata` method
has been implemetend replacing the current non standard method
"change_content_type".
Aliasing the old method to the newer one and deprecating the old method
won't work since the method signatures are not the same. Plus it was
used as a hack/non standard method workaround.

- Misc changes:
 - Rubocop cleanup + test updates.
 - Content type is now only guessed if rails does not send it as a meta
parameter. However guessing content type inside the provider class is
unnecessary starting from version 5.2.1.1.
Will consider removing this altogether in a future release
 - Update tests accordingly.
 - Send Content-Disposition header in #upload definition if filename and
disposition are passed as params.
