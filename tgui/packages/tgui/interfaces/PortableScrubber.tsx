// Port of NSV13 tgui/interfaces/PortableScrubber.js (Inferno) to TGMC React/TS. Mechanical conversion, not compiled.
import { useBackend } from '../backend';
import { Box, Section, LabeledList, Button, AnimatedNumber, NumberInput } from 'tgui-core/components';
import { getGasLabel } from '../constants';
import { Window } from '../layouts';
import { PortableBasicInfo } from './common/PortableAtmos';

export const PortableScrubber = (props: any) => {
  const { act, data } = useBackend<any>();

  const filter_types = data.filter_types || [];

  return (
    <Window
      width={320}
      height={350}>
      <Window.Content>
        <PortableBasicInfo />
        <Section title="Filters">
          {filter_types.map(filter => (
            <Button
              key={filter.id}
              icon={filter.enabled ? 'check-square-o' : 'square-o'}
              content={getGasLabel(filter.gas_id, filter.gas_name)}
              selected={filter.enabled}
              onClick={() => act('toggle_filter', {
                val: filter.gas_id,
              })} />
          ))}
        </Section>
      </Window.Content>
    </Window>
  );
};
