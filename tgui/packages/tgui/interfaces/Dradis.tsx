// Port of NSV13 tgui/interfaces/Dradis.js (+ components/Map.js) from Inferno/JS to React/TS. Same ui_data / ui_act contract as nsv13/code/modules/overmap/radar.dm.
import { useEffect, useRef } from 'react';
import { Button, Knob, Section } from 'tgui-core/components';
import { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';
import { NSV_SPACE_BG } from './NsvAssets';

const CSS = `
.sc-outer{overflow:hidden;position:relative;width:100%;background-image:url(NSV_SPACE_BG);border:1px solid #40628a;cursor:grab}
.sc-inner{position:relative;width:4000px;height:4000px;background-size:40px 40px;background-image:radial-gradient(circle at center,#360 1px,rgba(0,0,0,0) 1px)}
.sc-range{position:absolute;border-radius:50%;border:2px solid #360;transition:all .5s ease-out}
.star_marker_syndicate,.star_marker_nanotrasen,.star_marker_unaligned,.star_marker_uncharted{display:inline-block;padding:0 5px;color:rgba(0,0,0,0);line-height:25px;width:25px;height:25px;min-width:25px;min-height:25px;margin-left:-12px;margin-bottom:-12px;border-radius:50%;z-index:3;outline:0}
.star_marker_syndicate{background:radial-gradient(ellipse at center,#a30000 0%,#a30000 20%,rgba(163,0,0,.71) 40%,rgba(163,0,0,0) 60%)}
.star_marker_nanotrasen{background:radial-gradient(ellipse at center,cornflowerblue 0%,cornflowerblue 20%,rgba(100,149,237,.71) 40%,rgba(100,149,237,0) 60%)}
.star_marker_unaligned,.star_marker_uncharted{background:radial-gradient(ellipse at center,#a66300 0%,#a66300 20%,rgba(166,99,0,.71) 40%,rgba(166,99,0,0) 60%)}
span.star_label{position:relative;color:#fff;white-space:nowrap;left:5px;bottom:-25px}
span.star_label p{position:absolute;left:50%;transform:translate(-50%,-15px);text-shadow:1px 1px 0 #0ff;margin:0}
`.replace('NSV_SPACE_BG', NSV_SPACE_BG);

type Ship = {
  id?: string;
  name: string;
  x: number;
  y: number;
  alignment: string;
  colour: string;
  opacity: number;
};

type Data = {
  ships: Ship[];
  zoom_factor: number;
  zoom_factor_min: number;
  zoom_factor_max: number;
  focus_x: number;
  focus_y: number;
  width_mod: number;
  showFriendlies: number;
  showEnemies: number;
  showAsteroids: number;
  showAnomalies: number;
  sensor_mode: string;
  pulse_delay: string;
  dradis_targeting: BooleanLike;
  can_target: BooleanLike;
  can_radar_pulse: BooleanLike;
  can_use_radar: BooleanLike;
};

const HALF = 2000;

/** NSV13 Map: a draggable container that starts focused on the middle. */
const DradisMapView = (props: { height: string; children: React.ReactNode }) => {
  const ref = useRef<HTMLDivElement>(null);
  const focus = () => {
    const map = ref.current;
    if (map) {
      map.scrollLeft = HALF - map.clientWidth / 2;
      map.scrollTop = HALF - map.clientHeight / 2;
    }
  };
  useEffect(focus, []);
  const onMouseDown = (e: React.MouseEvent) => {
    let curX = e.screenX;
    let curY = e.screenY;
    const move = (ev: MouseEvent) => {
      ev.preventDefault();
      const map = ref.current;
      if (map) {
        map.scrollLeft -= ev.screenX - curX;
        map.scrollTop -= ev.screenY - curY;
        curX = ev.screenX;
        curY = ev.screenY;
      }
    };
    const up = () => {
      document.removeEventListener('mousemove', move);
      document.removeEventListener('mouseup', up);
    };
    document.addEventListener('mousemove', move);
    document.addEventListener('mouseup', up);
  };
  return (
    <div className="sc-outer" ref={ref} onMouseDown={onMouseDown} style={{ height: props.height }}>
      <div className="sc-inner">{props.children}</div>
    </div>
  );
};

const FilterKnob = (props: { label: string; value: number; action: string }) => {
  const { act } = useBackend<Data>();
  return (
    <>
      {props.label}
      <Knob
        inline
        mx={1}
        color={!!props.value && 'green'}
        value={props.value}
        unit="scan strength"
        minValue={0}
        maxValue={100}
        step={1}
        stepPixelSize={1}
        onDrag={(e, value) => act(props.action, { alpha: value })}
      />
    </>
  );
};

export const DradisContent = (props: { height?: string }) => {
  const { act, data } = useBackend<Data>();
  const zoom = data.zoom_factor;
  const scale = 5 * zoom;
  const diameter = data.width_mod * 562.5 * zoom;

  const drawShip = (ship: Ship, index: number) => (
    <Button
      key={ship.id || `${ship.name}-${index}`}
      className={`star_marker_${ship.alignment}`}
      onClick={() => ship.id && act('hail', { target: ship.id })}
      style={{
        height: '1px',
        position: 'absolute',
        left: `${HALF + (ship.x - data.focus_x) * scale}px`,
        bottom: `${HALF + (ship.y - data.focus_y) * scale}px`,
        border: `1px solid ${ship.colour}`,
        opacity: ship.opacity,
        transition: 'all 0.5s ease-out',
      }}
    >
      <span className="star_label">
        <p>{ship.name}</p>
      </span>
    </Button>
  );

  return (
    <Section
      title="Settings:"
      buttons={
        <>
          <Button icon="search-plus" onClick={() => act('zoomin')} />
          <Button icon="search-minus" onClick={() => act('zoomout')} />
          {!!data.can_use_radar && (
            <>
              <Button icon="bullseye" disabled={!data.can_radar_pulse} onClick={() => act('radar_pulse')}>
                Radar Pulse
              </Button>
              <Button icon="project-diagram" onClick={() => act('sensor_mode')}>
                {data.sensor_mode}
              </Button>
              <Button icon="stopwatch" onClick={() => act('radar_delay')}>
                {data.pulse_delay}
              </Button>
            </>
          )}
          {!!data.can_target && (
            <Button
              icon={data.dradis_targeting ? 'bullseye' : 'square-o'}
              color={data.dradis_targeting ? 'bad' : 'good'}
              onClick={() => act('dradis_targeting')}
            >
              {data.dradis_targeting ? 'Targeting' : 'Hailing'}
            </Button>
          )}
        </>
      }
    >
      <style>{CSS}</style>
      <FilterKnob label="Allies:" value={data.showFriendlies} action="showFriendlies" />
      <FilterKnob label="Enemies:" value={data.showEnemies} action="showEnemies" />
      <FilterKnob label="Asteroids:" value={data.showAsteroids} action="showAsteroids" />
      <FilterKnob label="Anomalies:" value={data.showAnomalies} action="showAnomalies" />
      Zoom:
      <Knob
        inline
        mx={1}
        color="green"
        value={zoom * 100}
        unit="%"
        minValue={data.zoom_factor_min * 100}
        maxValue={data.zoom_factor_max * 100}
        step={1}
        stepPixelSize={1}
        onDrag={(e, value) => act('setZoom', { zoom: value })}
      />
      <DradisMapView height={props.height || '75vh'}>
        {(data.ships || []).map(drawShip)}
        <div
          className="sc-range"
          style={{
            left: `${HALF - diameter / 2}px`,
            bottom: `${HALF - diameter / 2}px`,
            width: `${diameter}px`,
            height: `${diameter}px`,
          }}
        />
      </DradisMapView>
    </Section>
  );
};

export const Dradis = () => (
  <Window theme="hackerman" width={700} height={750}>
    <Window.Content scrollable>
      <DradisContent />
    </Window.Content>
  </Window>
);
