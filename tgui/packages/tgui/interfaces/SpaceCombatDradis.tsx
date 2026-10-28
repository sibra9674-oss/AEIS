// Port of NSV13 tgui/interfaces/Dradis.js + components/Map.js (+ Map.scss), converted from Inferno/JS to React/TS.
import { Button, Knob, Section } from 'tgui-core/components';
import { useEffect, useRef } from 'react';

import { useBackend } from '../backend';
import { Window } from '../layouts';
import { SPACE_BG } from './SpaceCombatAssets';

const CSS = `
.sc-outer{overflow:hidden;position:relative;width:100%;background-image:url(SPACE_BG);border:1px solid #40628a;cursor:grab}
.sc-inner{position:relative;width:4000px;height:4000px;background-size:40px 40px;background-image:radial-gradient(circle at center,#360 1px,rgba(0,0,0,0) 1px)}
.sc-range{position:absolute;border-radius:50%;border:2px solid #360;transition:all .5s ease-out}
.star_marker_syndicate,.star_marker_nanotrasen{display:inline-block;padding:0 5px;color:rgba(0,0,0,0);line-height:25px;width:25px;height:25px;min-width:25px;min-height:25px;margin-left:-12px;margin-bottom:-12px;border-radius:50%;z-index:3;outline:0}
.star_marker_syndicate{background:radial-gradient(ellipse at center,#a30000 0%,#a30000 20%,rgba(163,0,0,.71) 40%,rgba(163,0,0,0) 60%)}
.star_marker_nanotrasen{background:radial-gradient(ellipse at center,cornflowerblue 0%,cornflowerblue 20%,rgba(100,149,237,.71) 40%,rgba(100,149,237,0) 60%)}
span.star_label{position:relative;color:#fff;white-space:nowrap;left:5px;bottom:-25px}
span.star_label p{position:absolute;left:50%;transform:translate(-50%,-15px);text-shadow:1px 1px 0 #0ff;margin:0}
`.replace('SPACE_BG', SPACE_BG);

type Ship = {
  id: string;
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
  showFriendlies: number;
  showEnemies: number;
  radar_range: number;
};

const SIZE = 4000;
const HALF = SIZE / 2;

/** NSV13 Map: a draggable (scrollable) container that starts focused on the middle. */
const DradisMapView = (props: {
  scale: number;
  height: string;
  children: React.ReactNode;
}) => {
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
    <div
      className="sc-outer"
      ref={ref}
      onMouseDown={onMouseDown}
      style={{ height: props.height }}
    >
      <div className="sc-inner">{props.children}</div>
    </div>
  );
};

export const DradisContent = (props: { height?: string }) => {
  const { act, data } = useBackend<Data>();
  const zoom = data.zoom_factor;
  const scale = 5 * zoom;
  const diameter = data.radar_range * 2 * scale;

  const drawShips = (ship: Ship) => (
    <Button
      key={ship.id}
      className={`star_marker_${ship.alignment}`}
      style={{
        height: '1px',
        position: 'absolute',
        left: `${HALF + ship.x * scale}px`,
        bottom: `${HALF + ship.y * scale}px`,
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
          <Button icon="camera" onClick={() => location.reload()}>
            Re-focus
          </Button>
        </>
      }
    >
      <style>{CSS}</style>
      Allies:
      <Knob
        inline
        mx={1}
        color={!!data.showFriendlies && 'green'}
        value={data.showFriendlies}
        unit="scan strength"
        minValue={0}
        maxValue={100}
        step={1}
        stepPixelSize={1}
        onDrag={(e, value) => act('showFriendlies', { alpha: value })}
      />
      Enemies:
      <Knob
        inline
        mx={1}
        color={!!data.showEnemies && 'green'}
        value={data.showEnemies}
        unit="scan strength"
        minValue={0}
        maxValue={100}
        step={1}
        stepPixelSize={1}
        onDrag={(e, value) => act('showEnemies', { alpha: value })}
      />
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
      <DradisMapView scale={scale} height={props.height || '75vh'}>
        {(data.ships || []).map(drawShips)}
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

export const SpaceCombatDradis = () => (
  <Window theme="hackerman" width={700} height={750}>
    <Window.Content scrollable>
      <DradisContent />
    </Window.Content>
  </Window>
);
