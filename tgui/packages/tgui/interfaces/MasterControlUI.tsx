// Unified helm + tactical console: the NSV tactical panel plus flight controls.
import { Button, LabeledList, Section } from 'tgui-core/components';
import { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';
import { TacticalContent, TacticalData } from './TacticalConsole';

type Data = TacticalData & {
  angle: number;
  desired_angle: number;
  speed_limit: number;
  inertial_dampeners: BooleanLike;
  brakes: BooleanLike;
  rcs_mode: BooleanLike;
  move_by_mouse: BooleanLike;
  mass: number;
  faction: string;
};

export const MasterControlUI = () => {
  const { act, data } = useBackend<Data>();
  return (
    <Window theme="nanotrasen" width={560} height={760}>
      <Window.Content scrollable>
        <Section title="Flight">
          <LabeledList>
            <LabeledList.Item label="Heading">{Math.round(data.angle)}°</LabeledList.Item>
            <LabeledList.Item label="Speed limit">{data.speed_limit}</LabeledList.Item>
          </LabeledList>
          <Button selected={!!data.inertial_dampeners} onClick={() => act('toggle_dampeners')}>
            Inertial dampeners
          </Button>
          <Button selected={!!data.brakes} onClick={() => act('toggle_brakes')}>
            Brakes
          </Button>
          <Button selected={!!data.rcs_mode} onClick={() => act('toggle_rcs')}>
            RCS
          </Button>
          <Button selected={!!data.move_by_mouse} onClick={() => act('toggle_mouse_steering')}>
            Mouse steering
          </Button>
          <Button icon="angles-up" onClick={() => act('boost', { direction: 1 })}>
            Boost
          </Button>
        </Section>
        <TacticalContent />
      </Window.Content>
    </Window>
  );
};
