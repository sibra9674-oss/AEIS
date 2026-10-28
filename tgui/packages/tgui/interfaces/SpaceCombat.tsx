import {
  Box,
  Button,
  LabeledList,
  NoticeBox,
  ProgressBar,
  Section,
  Stack,
} from 'tgui-core/components';
import { BooleanLike } from 'tgui-core/react';
import { useRef, useState } from 'react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type Contact = {
  ref: string;
  name: string;
  dx: number;
  dy: number;
  heading: number;
  hull: number;
  max_hull: number;
  range: number;
  bearing: number;
  rel_bearing: number;
};

type Weapon = {
  index: number;
  name: string;
  damage: number;
  range: number;
  arc: number;
  ammo: number;
  cooldown_left: number;
  error: string | null;
  selected: BooleanLike;
};

type Data = {
  destroyed: BooleanLike;
  name: string;
  hull: number;
  max_hull: number;
  max_armour: number;
  armour: { name: string; value: number }[];
  heading: number;
  desired_heading: number;
  speed: number;
  max_speed: number;
  vel_x: number;
  vel_y: number;
  throttle: number;
  dampeners: BooleanLike;
  brakes: BooleanLike;
  boost_ready: BooleanLike;
  radar_range: number;
  observing: BooleanLike;
  is_admin: BooleanLike;
  target_ref: string | null;
  contacts: Contact[];
  projectiles: { dx: number; dy: number; friendly: BooleanLike }[];
  weapons: Weapon[];
  log: string[];
};

const SIZE = 520;
const C = SIZE / 2;
const rad = (deg: number) => (deg * Math.PI) / 180;

const glow = (color: string) =>
  `radial-gradient(ellipse at center, ${color} 0%, ${color} 20%, ${color}b5 40%, ${color}00 60%)`;

/** NSV13-style Dradis: starfield, dotted grid, green range rings, glowing labelled blips, drag to pan. */
const Radar = (props: { data: Data }) => {
  const { act } = useBackend<Data>();
  const { data } = props;
  const [pan, setPan] = useState({ x: 0, y: 0 });
  const drag = useRef<{ x: number; y: number } | null>(null);
  const scale = (C - 10) / data.radar_range;
  const cx = C + pan.x;
  const cy = C + pan.y;
  const px = (dx: number) => cx + dx * scale;
  const py = (dy: number) => cy - dy * scale;
  const hx = cx + Math.sin(rad(data.desired_heading)) * (C - 10);
  const hy = cy - Math.cos(rad(data.desired_heading)) * (C - 10);

  return (
    <Box>
      <div
        style={{
          position: 'relative',
          width: `${SIZE}px`,
          height: `${SIZE}px`,
          overflow: 'hidden',
          cursor: 'grab',
          border: '1px solid #40628a',
          backgroundColor: '#000308',
          backgroundImage:
            'radial-gradient(circle at center, #360 1px, rgba(0,0,0,0) 1px)',
          backgroundSize: '40px 40px',
          backgroundPosition: `${pan.x}px ${pan.y}px`,
          userSelect: 'none',
        }}
        onMouseDown={(e) => {
          drag.current = { x: e.screenX, y: e.screenY };
        }}
        onMouseMove={(e) => {
          if (!drag.current) {
            return;
          }
          const dx = e.screenX - drag.current.x;
          const dy = e.screenY - drag.current.y;
          drag.current = { x: e.screenX, y: e.screenY };
          setPan((old) => ({ x: old.x + dx, y: old.y + dy }));
        }}
        onMouseUp={() => {
          drag.current = null;
        }}
        onMouseLeave={() => {
          drag.current = null;
        }}
      >
        <svg
          width={SIZE}
          height={SIZE}
          style={{ position: 'absolute', left: 0, top: 0, pointerEvents: 'none' }}
        >
          {[1, 2, 3, 4].map((i) => (
            <g key={i}>
              <circle
                cx={cx}
                cy={cy}
                r={((C - 10) * i) / 4}
                fill="none"
                stroke="#360"
                strokeWidth={2}
              />
              <text
                x={cx + 4}
                y={cy - ((C - 10) * i) / 4 + 12}
                fill="#5a9a3a"
                fontSize="10"
              >
                {Math.round((data.radar_range * i) / 4)}
              </text>
            </g>
          ))}
          <g transform={`translate(${cx},${cy})`}>
            <path
              d={`M 0 0 L 0 ${-(C - 10)} A ${C - 10} ${C - 10} 0 0 0 ${-(C - 10) * Math.sin(rad(40))} ${-(C - 10) * Math.cos(rad(40))} Z`}
              fill="#2fd15f"
              fillOpacity={0.12}
            >
              <animateTransform
                attributeName="transform"
                type="rotate"
                from="0"
                to="360"
                dur="4s"
                repeatCount="indefinite"
              />
            </path>
          </g>
          <line
            x1={cx}
            y1={cy}
            x2={hx}
            y2={hy}
            stroke="#e6d94a"
            strokeDasharray="3 5"
            opacity={0.7}
          />
          <line
            x1={cx}
            y1={cy}
            x2={px(data.vel_x * 5)}
            y2={py(data.vel_y * 5)}
            stroke="#ffffff"
            strokeWidth={2}
            opacity={0.8}
          />
          {data.projectiles.map((p, i) => (
            <circle
              key={i}
              cx={px(p.dx)}
              cy={py(p.dy)}
              r={2.5}
              fill={p.friendly ? '#4fe3ff' : '#ff9a3c'}
            />
          ))}
          {data.contacts.map((c) => (
            <line
              key={c.ref}
              x1={px(c.dx)}
              y1={py(c.dy)}
              x2={px(c.dx) + Math.sin(rad(c.heading)) * 16}
              y2={py(c.dy) - Math.cos(rad(c.heading)) * 16}
              stroke="#ff7b7b"
              strokeWidth={2}
            />
          ))}
        </svg>
        {data.contacts.map((c) => {
          const isTarget = c.ref === data.target_ref;
          return (
            <div
              key={c.ref}
              title={`${c.name}: ${c.range}`}
              onMouseDown={(e) => e.stopPropagation()}
              onClick={() => act('target', { ref: c.ref })}
              style={{
                position: 'absolute',
                left: `${px(c.dx) - 12}px`,
                top: `${py(c.dy) - 12}px`,
                width: '25px',
                height: '25px',
                borderRadius: '50%',
                background: glow('#ff3b3b'),
                border: isTarget ? '1px dashed #fff' : 'none',
                cursor: 'pointer',
                transition: 'all 0.2s linear',
              }}
            >
              <span
                style={{
                  position: 'absolute',
                  left: '28px',
                  top: '-2px',
                  color: '#fff',
                  whiteSpace: 'nowrap',
                  textShadow: '1px 1px 0 #0ff',
                  fontSize: '11px',
                }}
              >
                {c.name} · {Math.round(c.range)} ·{' '}
                {Math.round((c.hull / c.max_hull) * 100)}%
              </span>
            </div>
          );
        })}
        <div
          style={{
            position: 'absolute',
            left: `${cx - 12}px`,
            top: `${cy - 12}px`,
            width: '25px',
            height: '25px',
            borderRadius: '50%',
            background: glow('#6495ed'),
            pointerEvents: 'none',
          }}
        />
        <div
          style={{
            position: 'absolute',
            left: `${cx - 4}px`,
            top: `${cy - 5}px`,
            width: 0,
            height: 0,
            borderLeft: '4px solid transparent',
            borderRight: '4px solid transparent',
            borderBottom: '10px solid #b9ffcf',
            transform: `rotate(${data.heading}deg)`,
            transformOrigin: '4px 5px',
            pointerEvents: 'none',
          }}
        />
        <Box
          position="absolute"
          left="6px"
          top="4px"
          color="#5a9a3a"
          fontSize="11px"
        >
          N ↑ · drag to pan
        </Box>
      </div>
      <Button mt={1} compact icon="crosshairs" onClick={() => setPan({ x: 0, y: 0 })}>
        Re-focus
      </Button>
    </Box>
  );
};

export const SpaceCombat = () => {
  const { act, data } = useBackend<Data>();

  if (data.destroyed) {
    return (
      <Window width={400} height={200} title="Tactical helm">
        <Window.Content>
          <NoticeBox danger>SHIP DESTROYED</NoticeBox>
        </Window.Content>
      </Window>
    );
  }

  return (
    <Window width={1000} height={820} title="Tactical helm">
      <Window.Content scrollable>
        <Stack>
          <Stack.Item>
            <Radar data={data} />
            <Box color="label" mt={1}>
              Range:{' '}
              {[20, 30, 45].map((r) => (
                <Button
                  key={r}
                  compact
                  selected={data.radar_range === r}
                  onClick={() => act('zoom', { value: r })}
                >
                  {r} u
                </Button>
              ))}
            </Box>
            <Box color="label" fontSize="11px">
              Green: our ship. Red: hostile. Yellow dashed: ordered heading.
              White: velocity.
            </Box>
          </Stack.Item>
          <Stack.Item grow>
            <Section title={data.name}>
              <ProgressBar
                value={data.hull}
                minValue={0}
                maxValue={data.max_hull}
                color="good"
              >
                Hull {data.hull}/{data.max_hull}
              </ProgressBar>
              {data.armour.map((a) => (
                <ProgressBar
                  key={a.name}
                  mt={0.5}
                  value={a.value}
                  minValue={0}
                  maxValue={data.max_armour}
                  color="blue"
                >
                  {a.name} {a.value}/{data.max_armour}
                </ProgressBar>
              ))}
            </Section>
            <Section title="Helm">
              <LabeledList>
                <LabeledList.Item label="Heading">
                  {data.heading}° (ordered {data.desired_heading}°)
                </LabeledList.Item>
                <LabeledList.Item label="Speed">
                  {data.speed} / {data.max_speed}/s
                </LabeledList.Item>
                <LabeledList.Item label="Throttle">
                  {[0, 25, 50, 75, 100].map((v) => (
                    <Button
                      key={v}
                      compact
                      selected={data.throttle === v}
                      onClick={() => act('throttle', { value: v })}
                    >
                      {v}
                    </Button>
                  ))}
                </LabeledList.Item>
                <LabeledList.Item label="Turn">
                  {[-90, -45, -15, 15, 45, 90].map((v) => (
                    <Button
                      key={v}
                      compact
                      onClick={() => act('turn', { value: v })}
                    >
                      {v > 0 ? `+${v}` : v}
                    </Button>
                  ))}
                </LabeledList.Item>
                <LabeledList.Item label="Systems">
                  <Button
                    selected={data.dampeners}
                    onClick={() => act('dampeners')}
                  >
                    IAS {data.dampeners ? 'ON' : 'OFF'}
                  </Button>
                  <Button
                    selected={data.brakes}
                    onClick={() => act('brakes')}
                  >
                    Brakes
                  </Button>
                  <Button
                    color="average"
                    disabled={!data.boost_ready}
                    onClick={() => act('boost')}
                  >
                    Boost
                  </Button>
                </LabeledList.Item>
              </LabeledList>
              <Button
                mt={1}
                fluid
                icon="eye"
                color={data.observing ? 'bad' : 'good'}
                onClick={() => act('view')}
              >
                {data.observing ? 'Leave ship view' : 'Re-enter ship view'}
              </Button>
              <Box color="label" fontSize="11px" mt={0.5}>
                Ship view: W/S thrust, A/D turn (IAS on) or strafe, Q/E rotate, Shift boost, Alt brakes, X IAS, Space or 1-4 weapon, click = fire.
              </Box>
            </Section>
            <Section title="Weapons">
              {data.weapons.map((w) => (
                <Box key={w.index} mb={1}>
                  <Button
                    compact
                    selected={w.selected}
                    onClick={() => act('select_weapon', { index: w.index })}
                  >
                    {w.name}
                  </Button>{' '}
                  <Box as="span" color="label">
                    dmg {w.damage}, {w.range}, arc ±{w.arc}°, ammo{' '}
                    {w.ammo < 0 ? '∞' : w.ammo}
                  </Box>
                  <br />
                  <Box as="span" color={w.error ? 'average' : 'good'}>
                    {w.error
                      ? `${w.error}${w.cooldown_left ? ` (${w.cooldown_left}s)` : ''}`
                      : 'READY'}
                  </Box>{' '}
                  <Button
                    compact
                    color="bad"
                    disabled={!!w.error}
                    onClick={() => act('fire', { index: w.index })}
                  >
                    FIRE
                  </Button>
                </Box>
              ))}
            </Section>
          </Stack.Item>
        </Stack>
        <Section title="Contacts">
          {data.contacts.length === 0 && <Box color="label">No contacts.</Box>}
          {data.contacts.map((c) => (
            <Box key={c.ref}>
              <Button
                compact
                selected={c.ref === data.target_ref}
                onClick={() => act('target', { ref: c.ref })}
              >
                {c.name}
              </Button>{' '}
              range {c.range}, bearing {c.bearing}° (rel{' '}
              {c.rel_bearing > 0 ? '+' : ''}
              {c.rel_bearing}), hull {c.hull}/{c.max_hull}
            </Box>
          ))}
        </Section>
        <Section title="Log">
          {[...data.log].reverse().map((line, i) => (
            <Box key={i} color="label">
              {line}
            </Box>
          ))}
        </Section>
        {!!data.is_admin && (
          <Section title="Admin">
            <Button onClick={() => act('spawn_raiders')}>Spawn 2 raiders</Button>
            <Button onClick={() => act('spawn_cruiser')}>Spawn cruiser</Button>
          </Section>
        )}
      </Window.Content>
    </Window>
  );
};
