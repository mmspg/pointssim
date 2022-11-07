
# PointSSIM: Point cloud structural similarity metric


In this repository, scripts for the computation of point cloud structural similarity scores and pre-processing stages defined in [1] (i.e., point fusion, voxelization, attribute estimation), are released. Regarding pre-processing, with point fusion, duplicated point coordinates are discarded and corresponding color values are averaged. Voxelization is optionally enabled to simulate inspection from further distances, similarly to downsampling in 2D imaging. Attribute estimation is necessary, when normal vectors and/or curvatures are not present. Regarding the execution of the metric, structural similarity scores are computed based on the comparison of feature maps that reflect local properties of point cloud attributes; in our case, geometry, normals, curvatures or colors. In some aspect, we explore the applicability of the well-known SSIM in a higher-dimensional, irregular space (volumetric content), incorporating geometrical and textural information.

The provided scipts are organized in four folders, and a main that serves as an example of their usage:

- **point_fusion**: Script to fuse points with duplicate coordinates in a point cloud. Corresponding color values are averaged, if present, and unique coordinates are kept. 

  To apply point fusion:

  `[pcOut] = pc_fuse_points(pcIn)`

  with `pcIn` an input pointCloud object or path to file, and `pcOut` an output pointCloud object.

- **voxelization**: Script to voxelize a point cloud at a target bit-depth. The script takes as input a voxelized point cloud with optional color values. The output voxels are scaled through an affine transformation that mantains the ratios of lengths of parallel segments. After scaling, points with same coordinates are discarded and corresponding color values are averaged.

  To voxelize a point cloud at a target bit-depth:

  `[pcOut] = pc_vox_scale(pcIn, voxIn, voxOut)`

  with `pcIn` an input pointCloud object or path to file, `voxIn` the bit-depth of the input, `voxOut` the target bit-depth of the output, and `pcOut` an output pointCloud object.

- **attribute_estimation**: Scripts to estimate normals and curvatures of a point cloud using quadric fitting. The neighbors required around every point for the fitting process can be identified using either k-nn or range-search algorithms. Moreover, the size of the neighborhood can be manually determined.

  To estimate normal and curvature attributes:

  `[normals, curvatures] = pc_estimate_norm_curv_qfit(pcIn, SEARCH_METHOD, SEARCH_SIZE)`

  with `pcIn` a pointCloud object or path to file, `SEARCH_METHOD` the selected method to identify neighborhoods, with available options: `{'rs', 'knn'}`, and `SEARCH_SIZE` the size of neighborhoods. When `SEARCH_METHOD` is set to `'rs'` the range-search algorithm is used and the `SEARCH_SIZE` corresponds to the radius. When `SEARCH_METHOD`is set to `'knn'`, the k-nn algorithm is used and the `SEARCH_SIZE` corresponds to the k neighbors. The `normals` and `curvatures` indicate matrices with corresponding estimated point cloud attributes.

- **structucal_similarity**: Scripts to compute structural similarity scores for a point cloud under evaluation, when compared to a reference. A structural similarity score is obtained per attribute, namely, geometry, normal, curvature, and color. It is computed by pooling across the complement of 1 to an error map, which indicates the relative difference of associated feature maps extracted from the point clouds under comparison, as depicted in the figure below. The feature maps are computed using statistical dispersion estimators, applied on quantities that reflect attribute properties in local neighborhoods.

  To compute point cloud structural similarity scores:

  `[pssim] = pointssim(sA, sB, PARAMS)`

  with `sA` and `sB` custom structs for point clouds `A` and `B`, respectively, containing fields that correspond to the attributes under consideration.


For more details, the reader can refer to [1].

![alt text](/docs/similarity_score.png)
*\*Outline of point cloud similarity working principle. The depicted point cloud is part of the [**PointXR dataset**](https://www.epfl.ch/labs/mmspg/downloads/pointxr/) (original model source: [link](https://sketchfab.com/3d-models/hawaiian-tiki-3dscan-022f006c8ef647818d754195f02cb61f), creator: [Thomas Flynn](https://sketchfab.com/nebulousflynn), license: [CC Attribution](https://creativecommons.org/licenses/by/4.0/))*.


### Conditions of use

If you wish to use any of the provided scripts in your research, we kindly ask you to cite [1].


### References

[1] E. Alexiou and T. Ebrahimi, "[Towards a Point Cloud Structural Similarity Metric](https://infoscience.epfl.ch/record/277379?ln=en)," *2020 IEEE International Conference on Multimedia & Expo Workshops (ICMEW)*, London, United Kingdom, 2020, pp. 1-6. doi: [10.1109/ICMEW46912.2020.9106005](https://doi.org/10.1109/ICMEW46912.2020.9106005)
