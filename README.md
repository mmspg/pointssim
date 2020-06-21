
# PointSSIM: Towards a Point cloud Structural SIMilarity metric


In this repository, scripts for computation of structural similarity scores and voxelization of point clouds are provided. A similarity score is based on the comparison of feature maps that reflect local properties of a point cloud attribute. Voxelization is optionally enabled prior to feature extraction, similarly to downsampling in 2D imaging, to simulate inspection from further distances. In some aspect, our implementation aims at extending the well-known SSIM to a higher-dimensional space of volumetric content.

The provided material is organized in two folders:

* Similarity
Scripts to compute similarity scores for a point cloud under evaluation, when compared to a reference. A similarity score is obtained per attribute. It is computed by pooling across an error map, which indicates the relative difference of associated feature maps extracted from the point clouds under comparison. The feature maps are computed using statistical dispersion estimators, applied on quantities that reflect attribute properties in local regions. Point cloud attributes for both original and distorted models (e.g., color, normals) are assumed to be present. In case of absence, the corresponding similarity scores cannot be computed.

  To compute point cloud similarity scores:

  `[sim] = pc_ssim(pcA, pcB, PARAMS)`

* Voxelization
Script to voxelize a point cloud at a target bit-depth. The script currently handles voxelized inputs with (optional) color attributes, although it can be easily extended to non-voxelized models with multiple attributes. The script applies an affine transformation that scales the input geometry, maintaining the ratios of lengths of parallel segments. After the scaling process, points with the same coordinates are pruned, and their corresponding color values are blended.

  To voxelize a point cloud:

  `[pcOut] = pc_vox_scale(pcIn, voxIn, voxOut)`

The algorithmic steps that are employed in the proposed framework allow for different configurations, and facilitate the integration of new quantities, attributes and estimators.

For more details, the reader can refer to [1].

![alt text](/docs/similarity_score_2.png)
*\*Outline of point cloud similarity working principle. The depicted point cloud is part of the [**PointXR dataset**](https://www.epfl.ch/labs/mmspg/downloads/pointxr/) (original model source: [link](https://sketchfab.com/3d-models/hawaiian-tiki-3dscan-022f006c8ef647818d754195f02cb61f), creator: [Thomas Flynn](https://sketchfab.com/nebulousflynn), license: [CC Attribution](https://creativecommons.org/licenses/by/4.0/))*.


### Conditions of use

If you wish to use any of the provided scripts in your research, we kindly ask you to cite [1].


### References

[1] E. Alexiou and T. Ebrahimi, "[Towards a Point Cloud Structural Similarity Metric](https://infoscience.epfl.ch/record/277379?ln=en)," *2020 IEEE International Conference on Multimedia & Expo Workshops (ICMEW)*, London, United Kingdom, 2020, pp. 1-6. doi: [10.1109/ICMEW46912.2020.9106005](https://doi.org/10.1109/ICMEW46912.2020.9106005)
