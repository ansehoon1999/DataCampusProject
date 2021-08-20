# Maximum Coverage Location Problem.
제한된 시설물의 개수로 지역 수요를 최대한 많이 커버하기 위한 모델링 방법

### _inputs_
| num | parameter  | description  |
| --- | ---------- | ------------ |
|  1  | points     | 커버해야하는 지점들 |
|  2  | K          | 설치할 기기의 수 | 
|  3  | radius     | 한 기기가 커버하는 범위 |
|  4  | w          | 지점들의 중요도 벡터 |
|  5  | sites      | 기기가 들어설 수 있는 위치 |

### _outputs_
| num | parameter          | description  |
| --- | ------------------ | ------------ |
|  1  | opt_sites          | 기기가 설치될 위치 |
|  2  | m.objective_value  | 설치한 기기들로 커버가능한 수요 | 

<br><br><br>
---
reference: https://github.com/cyang-kth/maximum-coverage-location