# 배송 지연이 고객 이탈과 매출 손실에 미치는 영향 분석

> 이커머스 배송 데이터를 SQL·Python으로 검증하고 Metabase로 KPI를 모니터링하는 엔드투엔드 데이터 분석 프로젝트

**데이터**: Olist Brazilian E-Commerce (Kaggle, 2016–2018) 약 10만 주문  
**이벤트 로그**: 재구매 행동 시뮬레이션 320,759건 생성 (order_placed / order_delivered / review_submitted / repurchase)

---

## 목표

배송 지연이 고객 이탈 및 매출 손실로 이어지는지 가설 기반으로 정량화하고  
실무 수준의 ETL 파이프라인과 모니터링 대시보드를 구축한다.

---

## 가설 및 검증 결과

| #   | 가설                                                                     | 결과    | 핵심 수치                           | p-value    |
| --- | ------------------------------------------------------------------------ | ------- | ----------------------------------- | ---------- |
| H1  | 지연 일수가 3일 이내면 이탈 위험 고객 비율에 유의미한 차이가 없을 것이다 | ❌ 기각 | on_time 9.14% vs slight 31.55%      | p < 0.0001 |
| H2  | 지연을 경험한 고객은 정시 배송 고객 대비 이탈 위험 비율이 높을 것이다    | ✅ 채택 | on_time 9.14% vs delayed 60.61%     | p < 0.0001 |
| H3  | 배송 지연으로 인한 예상 매출 손실은 전체 매출의 5% 이상일 것이다         | ❌ 기각 | loss_ratio 4.65%                    | —          |
| H4  | 배송 지연 일수가 길어질수록 주문 취소율이 단조롭게 증가할 것이다         | ❌ 기각 | Spearman r = −0.40, U자형 패턴 확인 | p = 0.5046 |

**핵심 발견**: 지연 주문의 저평점 비율은 정시 배송의 **6.6배** (60.61% vs 9.14%)

---

## KPI 요약

| 지표                     | 값                |
| ------------------------ | ----------------- |
| 총 매출                  | 15,421,831.43 BRL |
| ARPU                     | 159.85 BRL        |
| 배송 지연율              | 6.77%             |
| At-Risk 고객 비율        | 12.62%            |
| 주문 취소율              | 0.63%             |
| 지연 주문 내 저평점 비율 | 60.61%            |

---

## 기술 스택

| 영역         | 기술                             |
| ------------ | -------------------------------- |
| 언어         | Python 3.12, SQL                 |
| 데이터베이스 | PostgreSQL 15                    |
| ETL          | SQLAlchemy, Pandas               |
| 통계 분석    | SciPy (Mann-Whitney U, Spearman) |
| 대시보드     | Metabase                         |
| 인프라       | Docker, Docker Compose           |

---

## 프로젝트 구조

```
├── notebooks/
│   ├── 01_eda.ipynb                  # 탐색적 데이터 분석
│   └── 02_hypothesis_testing.ipynb   # 가설 검증
├── sql/queries/
│   ├── h1_delay_threshold.sql
│   ├── h2_at_risk_comparison.sql
│   ├── h3_revenue_loss.sql
│   ├── h4_cancellation_rate.sql
│   ├── kpi.sql
│   └── validation.sql
├── etl/
│   ├── pipeline.py                   # ETL 전체 실행
│   ├── extract.py
│   ├── transform.py
│   ├── load.py
│   ├── db.py
│   └── simulation/
│       └── generate_event_logs.py    # 이벤트 로그 시뮬레이션 (320,759건)
└── docker-compose.yml                # PostgreSQL + Metabase
```

---

## 실행 방법

**1. 환경 변수 설정**

```bash
cp .env.example .env
# 필요 시 `.env` 값을 수정하세요.
```

**2. 컨테이너 실행**

```bash
docker compose up -d
# PostgreSQL → localhost:${POSTGRES_PORT}
# Metabase   → http://localhost:3000
```

**3. ETL 파이프라인 실행**

```bash
pip install -r requirements.txt
python -m etl.pipeline
python -m etl.simulation.generate_event_logs
```

**4. 가설 검증 SQL 실행**

DBeaver 등 SQL 클라이언트에서 `sql/queries/` 내 파일을 열어 실행하거나  
`.env` 설정값을 입력해 아래 명령어로 확인할 수 있습니다:

```bash
psql -h localhost -p 5432 -U your_user -d your_db \
  -f sql/queries/h2_at_risk_comparison.sql
```

## 분석 설계 원칙

- **지연 판정**: `EXTRACT(DAY FROM (delivered_at - estimated_at))::INT > 0` (전 SQL 통일)
- **리뷰 중복 처리**: `MIN(review_score) + GROUP BY order_id` (전 SQL 통일)
- **저평점 기준**: 리뷰 점수 1~2점

---

## 라이선스

데이터: [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) — CC BY-NC-SA 4.0
