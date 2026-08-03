import os
from contextlib import contextmanager
from datetime import datetime
from decimal import Decimal
from typing import Any

import psycopg
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from psycopg.rows import dict_row


DB_HOST = os.getenv("TESLAMATE_DB_HOST", "database")
DB_PORT = int(os.getenv("TESLAMATE_DB_PORT", "5432"))
DB_NAME = os.getenv("TESLAMATE_DB_NAME", "teslamate")
DB_USER = os.getenv("TESLAMATE_DB_USER", "teslamate")
DB_PASSWORD = os.getenv("TESLAMATE_DB_PASSWORD", "")
DB_SSLMODE = os.getenv("TESLAMATE_DB_SSLMODE", "disable")

app = FastAPI(title="Teji API", version="0.1.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=os.getenv("CORS_ALLOW_ORIGINS", "*").split(","),
    allow_credentials=False,
    allow_methods=["GET"],
    allow_headers=["*"],
)


def connection_info() -> dict[str, Any]:
    return {
        "host": DB_HOST,
        "port": DB_PORT,
        "dbname": DB_NAME,
        "user": DB_USER,
        "password": DB_PASSWORD,
        "sslmode": DB_SSLMODE,
    }


@contextmanager
def db():
    try:
        with psycopg.connect(**connection_info(), row_factory=dict_row) as conn:
            yield conn
    except psycopg.Error as exc:
        raise HTTPException(status_code=503, detail=f"Database unavailable: {exc}") from exc


def normalize(value: Any) -> Any:
    if isinstance(value, Decimal):
        return float(value)
    if isinstance(value, datetime):
        return value.isoformat()
    if isinstance(value, list):
        return [normalize(item) for item in value]
    if isinstance(value, dict):
        return {key: normalize(item) for key, item in value.items()}
    return value


def fetch_all(query: str, params: dict[str, Any] | None = None) -> list[dict[str, Any]]:
    with db() as conn:
        rows = conn.execute(query, params or {}).fetchall()
    return normalize(rows)


def fetch_one(query: str, params: dict[str, Any] | None = None) -> dict[str, Any] | None:
    with db() as conn:
        row = conn.execute(query, params or {}).fetchone()
    return normalize(row) if row else None


def address_label(alias: str) -> str:
    return (
        f"coalesce(nullif({alias}.name, ''), nullif({alias}.road, ''), "
        f"nullif({alias}.neighbourhood, ''), nullif({alias}.display_name, ''))"
    )


def nearest_address_join(position_alias: str, alias: str) -> str:
    return f"""
        left join lateral (
          select candidate.*
          from (
            select
              a.*,
              sqrt(
                power((a.latitude - {position_alias}.latitude)::float * 111000, 2) +
                power(
                  (a.longitude - {position_alias}.longitude)::float *
                  111000 * cos(radians({position_alias}.latitude::float)),
                  2
                )
              ) as meters
            from addresses a
            where a.latitude is not null
              and a.longitude is not null
              and {position_alias}.latitude is not null
              and {position_alias}.longitude is not null
          ) candidate
          where candidate.meters <= 300
          order by candidate.meters
          limit 1
        ) {alias} on true
    """


@app.get("/health")
def health() -> dict[str, Any]:
    row = fetch_one("select now() at time zone 'Asia/Shanghai' as checked_at")
    return {"ok": True, "checked_at": row["checked_at"]}


@app.get("/api/cars")
def cars() -> list[dict[str, Any]]:
    return fetch_all(
        """
        select
          c.id,
          c.name,
          c.model,
          c.trim_badging,
          c.marketing_name,
          c.exterior_color,
          c.wheel_type,
          c.display_priority
        from cars c
        order by coalesce(c.display_priority, c.id), c.id
        """
    )


@app.get("/api/overview")
def overview() -> dict[str, Any]:
    cars = fetch_all(
        f"""
        with today_drive_stats as (
          select
            car_id,
            count(*)::int as drives_today,
            coalesce(sum(distance), 0)::float as distance_today_km,
            coalesce(sum(duration_min), 0)::int as duration_today_min
          from drives
          where (start_date at time zone 'UTC' at time zone 'Asia/Shanghai')::date =
                (now() at time zone 'Asia/Shanghai')::date
          group by car_id
        ),
        latest_drive_ids as (
          select distinct on (car_id)
            id
          from drives
          where end_date is not null
          order by car_id, end_date desc
        ),
        last_drive as (
          select
            d.car_id,
            d.id as drive_id,
            d.start_date,
            d.end_date,
            d.distance,
            d.duration_min,
            d.speed_max,
            coalesce(sg.name, {address_label("sa")}, {address_label("sna")}) as start_name,
            coalesce(eg.name, {address_label("ea")}, {address_label("ena")}) as end_name
          from latest_drive_ids l
          join drives d on d.id = l.id
          left join positions sp on sp.id = d.start_position_id
          left join positions ep on ep.id = d.end_position_id
          left join addresses sa on sa.id = d.start_address_id
          left join addresses ea on ea.id = d.end_address_id
          left join geofences sg on sg.id = d.start_geofence_id
          left join geofences eg on eg.id = d.end_geofence_id
          {nearest_address_join("sp", "sna")}
          {nearest_address_join("ep", "ena")}
        )
        select
          c.id,
          c.name,
          c.model,
          c.trim_badging,
          c.marketing_name,
          ls.state,
          (ls.start_date at time zone 'UTC' at time zone 'Asia/Shanghai') as state_since,
          (lp.date at time zone 'UTC' at time zone 'Asia/Shanghai') as position_time,
          lp.latitude,
          lp.longitude,
          lp.speed,
          lp.power,
          lp.odometer,
          lp.battery_level,
          lp.usable_battery_level,
          lp.rated_battery_range_km,
          lp.outside_temp,
          lp.inside_temp,
          lp.tpms_pressure_fl,
          lp.tpms_pressure_fr,
          lp.tpms_pressure_rl,
          lp.tpms_pressure_rr,
          coalesce(tds.drives_today, 0) as drives_today,
          coalesce(tds.distance_today_km, 0) as distance_today_km,
          coalesce(tds.duration_today_min, 0) as duration_today_min,
          ld.drive_id as last_drive_id,
          (ld.start_date at time zone 'UTC' at time zone 'Asia/Shanghai') as last_drive_start,
          (ld.end_date at time zone 'UTC' at time zone 'Asia/Shanghai') as last_drive_end,
          ld.distance as last_drive_distance_km,
          ld.duration_min as last_drive_duration_min,
          ld.speed_max as last_drive_speed_max,
          ld.start_name as last_drive_start_name,
          ld.end_name as last_drive_end_name
        from cars c
        left join lateral (
          select
            s.state::text as state,
            s.start_date,
            s.end_date
          from states s
          where s.car_id = c.id
          order by s.start_date desc
          limit 1
        ) ls on true
        left join lateral (
          select
            p.date,
            p.car_id,
            p.latitude,
            p.longitude,
            p.speed,
            p.power,
            p.odometer,
            p.battery_level,
            p.usable_battery_level,
            p.rated_battery_range_km,
            p.outside_temp,
            p.inside_temp,
            p.tpms_pressure_fl,
            p.tpms_pressure_fr,
            p.tpms_pressure_rl,
            p.tpms_pressure_rr
          from positions p
          where p.car_id = c.id
          order by p.id desc
          limit 1
        ) lp on true
        left join today_drive_stats tds on tds.car_id = c.id
        left join last_drive ld on ld.car_id = c.id
        order by coalesce(c.display_priority, c.id), c.id
        """
    )
    return {"cars": cars}


@app.get("/api/drives")
def drives(
    car_id: int | None = None,
    limit: int = Query(default=50, ge=1, le=200),
) -> list[dict[str, Any]]:
    where = "where d.end_date is not null"
    params: dict[str, Any] = {"limit": limit}
    if car_id is not None:
        where += " and d.car_id = %(car_id)s"
        params["car_id"] = car_id

    return fetch_all(
        f"""
        select
          d.id,
          d.car_id,
          c.name as car_name,
          (d.start_date at time zone 'UTC' at time zone 'Asia/Shanghai') as start_date,
          (d.end_date at time zone 'UTC' at time zone 'Asia/Shanghai') as end_date,
          d.distance,
          d.duration_min,
          d.speed_max,
          d.power_max,
          d.power_min,
          d.ascent,
          d.descent,
          d.start_km,
          d.end_km,
          d.start_rated_range_km,
          d.end_rated_range_km,
          sp.battery_level as start_battery_level,
          ep.battery_level as end_battery_level,
          sp.usable_battery_level as start_usable_battery_level,
          ep.usable_battery_level as end_usable_battery_level,
          sp.latitude as start_latitude,
          sp.longitude as start_longitude,
          ep.latitude as end_latitude,
          ep.longitude as end_longitude,
          d.outside_temp_avg,
          d.inside_temp_avg,
          coalesce(sg.name, {address_label("sa")}, {address_label("sna")}) as start_name,
          coalesce(eg.name, {address_label("ea")}, {address_label("ena")}) as end_name
        from drives d
        join cars c on c.id = d.car_id
        left join positions sp on sp.id = d.start_position_id
        left join positions ep on ep.id = d.end_position_id
        left join addresses sa on sa.id = d.start_address_id
        left join addresses ea on ea.id = d.end_address_id
        left join geofences sg on sg.id = d.start_geofence_id
        left join geofences eg on eg.id = d.end_geofence_id
        {nearest_address_join("sp", "sna")}
        {nearest_address_join("ep", "ena")}
        {where}
        order by d.end_date desc
        limit %(limit)s
        """,
        params,
    )


@app.get("/api/drives/{drive_id}")
def drive_detail(drive_id: int) -> dict[str, Any]:
    drive = fetch_one(
        f"""
        select
          d.id,
          d.car_id,
          c.name as car_name,
          (d.start_date at time zone 'UTC' at time zone 'Asia/Shanghai') as start_date,
          (d.end_date at time zone 'UTC' at time zone 'Asia/Shanghai') as end_date,
          d.distance,
          d.duration_min,
          d.speed_max,
          d.power_max,
          d.power_min,
          d.ascent,
          d.descent,
          d.start_km,
          d.end_km,
          d.start_rated_range_km,
          d.end_rated_range_km,
          sp.battery_level as start_battery_level,
          ep.battery_level as end_battery_level,
          sp.usable_battery_level as start_usable_battery_level,
          ep.usable_battery_level as end_usable_battery_level,
          sp.latitude as start_latitude,
          sp.longitude as start_longitude,
          ep.latitude as end_latitude,
          ep.longitude as end_longitude,
          d.outside_temp_avg,
          d.inside_temp_avg,
          coalesce(sg.name, {address_label("sa")}, {address_label("sna")}) as start_name,
          coalesce(eg.name, {address_label("ea")}, {address_label("ena")}) as end_name
        from drives d
        join cars c on c.id = d.car_id
        left join positions sp on sp.id = d.start_position_id
        left join positions ep on ep.id = d.end_position_id
        left join addresses sa on sa.id = d.start_address_id
        left join addresses ea on ea.id = d.end_address_id
        left join geofences sg on sg.id = d.start_geofence_id
        left join geofences eg on eg.id = d.end_geofence_id
        {nearest_address_join("sp", "sna")}
        {nearest_address_join("ep", "ena")}
        where d.id = %(drive_id)s
        """,
        {"drive_id": drive_id},
    )
    if not drive:
        raise HTTPException(status_code=404, detail="Drive not found")

    route = fetch_all(
        """
        with numbered as (
          select
            row_number() over (order by date) as rn,
            row_number() over (order by speed desc nulls last, date) as speed_rank,
            count(*) over () as total,
            date,
            latitude,
            longitude,
            speed,
            power,
            odometer,
            battery_level,
            rated_battery_range_km,
            elevation,
            outside_temp,
            inside_temp
          from positions
          where drive_id = %(drive_id)s
            and latitude is not null
            and longitude is not null
        )
        select
          (date at time zone 'UTC' at time zone 'Asia/Shanghai') as date,
          latitude,
          longitude,
          speed,
          power,
          odometer,
          battery_level,
          rated_battery_range_km,
          elevation,
          outside_temp,
          inside_temp
        from numbered
        where total <= 1000
           or rn = 1
           or rn = total
           or speed_rank = 1
           or rn %% greatest(1, ceil(total / 1000.0)::int) = 0
        order by date
        """,
        {"drive_id": drive_id},
    )
    return {"drive": drive, "route": route}


@app.get("/api/charging-processes")
def charging_processes(
    car_id: int | None = None,
    limit: int = Query(default=50, ge=1, le=200),
) -> list[dict[str, Any]]:
    where = "where cp.end_date is not null"
    params: dict[str, Any] = {"limit": limit}
    if car_id is not None:
        where += " and cp.car_id = %(car_id)s"
        params["car_id"] = car_id

    return fetch_all(
        f"""
        select
          cp.id,
          cp.car_id,
          c.name as car_name,
          (cp.start_date at time zone 'UTC' at time zone 'Asia/Shanghai') as start_date,
          (cp.end_date at time zone 'UTC' at time zone 'Asia/Shanghai') as end_date,
          cp.charge_energy_added,
          cp.charge_energy_used,
          cp.start_battery_level,
          cp.end_battery_level,
          cp.duration_min,
          cp.outside_temp_avg,
          cp.cost,
          coalesce(g.name, a.display_name) as location_name
        from charging_processes cp
        join cars c on c.id = cp.car_id
        left join addresses a on a.id = cp.address_id
        left join geofences g on g.id = cp.geofence_id
        {where}
        order by cp.end_date desc
        limit %(limit)s
        """,
        params,
    )
